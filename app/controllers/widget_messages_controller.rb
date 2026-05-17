class WidgetMessagesController < ApplicationController
  include ActionController::Live

  APPROX_CHARS_PER_TOKEN = 4
  HISTORY_TOKEN_BUDGET = 1_200
  RECENT_MESSAGES_TO_KEEP_UNSUMMARIZED = 8
  MIN_MESSAGES_TO_SUMMARIZE = 12
  KNOWLEDGE_CHUNK_LIMIT = 6
  KNOWLEDGE_CONTEXT_MAX_CHARS = 4_000

  skip_before_action :authenticate_user!
  skip_forgery_protection
  before_action :set_cors_headers

  def create
    agent = widget_agent!
    return unless ensure_origin_allowed!(agent)

    message = params[:message].to_s.strip

    if message.blank?
      render json: { error: "Message can't be blank." }, status: :unprocessable_entity
      return
    end

    return unless ensure_usage_available!(agent)

    @conversation = find_or_create_conversation(agent)
    visitor_message = @conversation.messages.create!(role: "visitor", content: message)
    @conversation.touch_last_message_at!

    if ENV["OPENAI_API_KEY"].blank?
      render json: {
        error: "OPENAI_API_KEY is not configured.",
        conversation_token: @conversation.public_token
      }, status: :service_unavailable
      return
    end

    response = generate_reply(agent, @conversation, visitor_message)
    reply = response.content
    @conversation.messages.create!(role: "assistant", content: reply)
    @conversation.touch_last_message_at!
    record_message_usage(agent, @conversation, visitor_message.content, reply, response)

    render json: {
      reply: reply,
      conversation_token: @conversation.public_token
    }
  rescue RubyLLM::Error => error
    Rails.logger.error("RubyLLM error: #{error.class} - #{error.message}")
    render json: {
      error: "The AI assistant is not available right now.",
      conversation_token: @conversation&.public_token
    }, status: :bad_gateway
  end

  def stream
    set_stream_headers

    agent = widget_agent!
    return unless ensure_origin_allowed!(agent, stream: true)

    message = params[:message].to_s.strip

    if message.blank?
      write_sse(:error, error: "Message can't be blank.")
      return
    end

    return unless ensure_usage_available!(agent, stream: true)

    @conversation = find_or_create_conversation(agent)
    visitor_message = @conversation.messages.create!(role: "visitor", content: message)
    @conversation.touch_last_message_at!

    write_sse(:conversation, conversation_token: @conversation.public_token)

    if ENV["OPENAI_API_KEY"].blank?
      write_sse(:error, error: "OPENAI_API_KEY is not configured.")
      return
    end

    full_reply = +""
    response = stream_reply(agent, @conversation, visitor_message) do |delta|
      full_reply << delta
      write_sse(:delta, content: delta)
    end
    reply = full_reply.presence || response.content.to_s

    @conversation.messages.create!(role: "assistant", content: reply)
    @conversation.touch_last_message_at!
    record_message_usage(agent, @conversation, visitor_message.content, reply, response)
    write_sse(:done, conversation_token: @conversation.public_token)
  rescue RubyLLM::Error => error
    Rails.logger.error("RubyLLM stream error: #{error.class} - #{error.message}")
    write_sse(:error, error: "The AI assistant is not available right now.")
  ensure
    response.stream.close
  end

  def preflight
    head :ok
  end

  private

  def widget_agent!
    agent = Agent.find_by!(public_token: params[:agent_token])
    return agent if agent.active? || backoffice_preview_allowed?(agent)

    raise ActiveRecord::RecordNotFound
  end

  def ensure_origin_allowed!(agent, stream: false)
    return true if agent.origin_allowed?(request.origin) || backoffice_preview_allowed?(agent)

    if stream
      write_sse(:error, error: "This widget is not allowed on this domain.")
    else
      render json: { error: "This widget is not allowed on this domain." }, status: :forbidden
    end

    false
  end

  def ensure_usage_available!(agent, stream: false)
    return true unless agent.account.usage_limit_reached?

    if stream
      write_sse(:error, error: agent.account.usage_limit_message)
    else
      render json: { error: agent.account.usage_limit_message }, status: :payment_required
    end

    false
  end

  def backoffice_preview_allowed?(agent)
    same_backoffice_origin? && current_user&.account_id == agent.account_id
  end

  def same_backoffice_origin?
    request.origin == request.base_url ||
      request.referer.to_s.start_with?("#{request.base_url}/")
  end

  def find_or_create_conversation(agent)
    conversation = agent.conversations.find_by(public_token: params[:conversation_token])
    return conversation if conversation.present?

    agent.conversations.create!(
      visitor_identifier: params[:visitor_identifier].presence
    )
  end

  def generate_reply(agent, conversation, visitor_message)
    build_chat(agent, conversation, visitor_message).ask(visitor_message.content)
  end

  def stream_reply(agent, conversation, visitor_message)
    build_chat(agent, conversation, visitor_message).ask(visitor_message.content) do |chunk|
      delta = chunk.content.to_s
      next if delta.blank?

      yield delta
    end
  end

  def record_message_usage(agent, conversation, input_text, output_text, response)
    UsageEvent.record_message!(
      agent: agent,
      conversation: conversation,
      input_text: input_text,
      output_text: output_text,
      response: response
    )
  rescue ActiveRecord::ActiveRecordError => error
    Rails.logger.warn("Usage tracking skipped: #{error.class} - #{error.message}")
  end

  def build_chat(agent, conversation, visitor_message)
    summarize_old_messages_if_needed(conversation, visitor_message)

    RubyLLM.chat.tap do |chat|
      chat.with_instructions(agent_instructions(agent, visitor_message))

      if conversation.summary.present?
        chat.add_message(
          role: :user,
          content: "Earlier conversation summary:\n#{conversation.summary}"
        )
      end

      budgeted_recent_messages(conversation, visitor_message).each do |message|
        chat.add_message(role: ruby_llm_role(message), content: message.content)
      end
    end
  end

  def summarize_old_messages_if_needed(conversation, visitor_message)
    summarizable_messages = messages_after_summary(conversation)
      .where.not(id: visitor_message.id)
      .order(:created_at)

    return if summarizable_messages.count < MIN_MESSAGES_TO_SUMMARIZE

    messages_to_keep = summarizable_messages.last(RECENT_MESSAGES_TO_KEEP_UNSUMMARIZED)
    messages_to_summarize = summarizable_messages.to_a - messages_to_keep
    return if messages_to_summarize.blank?

    summary = summarize_messages(conversation.summary, messages_to_summarize)
    conversation.update!(
      summary: summary,
      summarized_until_message_id: messages_to_summarize.last.id
    )
  rescue RubyLLM::Error => error
    Rails.logger.warn("Conversation summary skipped: #{error.class} - #{error.message}")
  end

  def messages_after_summary(conversation)
    messages = conversation.messages
    return messages if conversation.summarized_until_message_id.blank?

    messages.where("id > ?", conversation.summarized_until_message_id)
  end

  def summarize_messages(existing_summary, messages)
    chat = RubyLLM.chat
    chat.with_instructions(<<~INSTRUCTIONS.squish)
      You summarize chatbot conversations for future context.
      Keep only facts that help answer later user messages: user needs,
      preferences, unresolved questions, decisions, and important product context.
      Be concise. Do not invent details.
    INSTRUCTIONS

    prompt = []
    prompt << "Existing summary:\n#{existing_summary}" if existing_summary.present?
    prompt << "New messages to merge into the summary:"
    prompt << messages.map { |message| "#{message.role}: #{message.content}" }.join("\n")
    prompt << "Return an updated summary in 8 bullet points or fewer."

    chat.ask(prompt.join("\n\n")).content
  end

  def budgeted_recent_messages(conversation, visitor_message)
    messages = messages_after_summary(conversation)
      .where.not(id: visitor_message.id)
      .order(created_at: :desc)

    budget = HISTORY_TOKEN_BUDGET * APPROX_CHARS_PER_TOKEN
    selected_messages = []
    used_chars = 0

    messages.each do |message|
      message_size = message.content.to_s.length + message.role.length + 2
      break if selected_messages.any? && used_chars + message_size > budget

      selected_messages << message
      used_chars += message_size
    end

    selected_messages.reverse
  end

  def ruby_llm_role(message)
    message.role == "assistant" ? :assistant : :user
  end

  def agent_instructions(agent, visitor_message)
    instructions = []
    instructions << agent.system_prompt if agent.system_prompt.present?
    instructions << "Tone: #{agent.tone}." if agent.tone.present?
    instructions << "Primary goal: #{agent.primary_goal}." if agent.primary_goal.present?
    instructions << knowledge_instructions(agent, visitor_message)
    instructions << "Keep replies concise, helpful, and directly useful to the visitor."
    instructions << "Format replies with normal spacing between words, dates, and punctuation. Use short paragraphs or bullet points when the answer contains multiple options."
    instructions.compact.join("\n\n")
  end

  def knowledge_instructions(agent, visitor_message)
    chunks = relevant_knowledge_chunks(agent, visitor_message.content)
    return if chunks.blank?

    context = chunks.map.with_index(1) do |chunk, index|
      "Knowledge chunk #{index}:\n#{chunk.content}"
    end.join("\n\n")

    <<~INSTRUCTIONS
      Use this knowledge base context as the source of truth for product, company, policy, pricing, menu, and documentation questions.
      If the visitor asks about something that is not present in this context, say that it is not available in the current knowledge base instead of inventing alternatives.

      Knowledge base context:
      #{context}
    INSTRUCTIONS
  end

  def relevant_knowledge_chunks(agent, query)
    vector_chunks = relevant_vector_chunks(agent, query)
    return vector_chunks if vector_chunks.present?

    relevant_keyword_chunks(agent, query)
  end

  def relevant_vector_chunks(agent, query)
    query_embedding = KnowledgeEmbedding.embed(query)
    return [] if query_embedding.blank?

    vector_sql = KnowledgeEmbedding.vector_sql(query_embedding)
    chunks = agent.knowledge_chunks
      .joins(:knowledge_source)
      .where(knowledge_sources: { status: "ready" })
      .where.not(embedding: nil)
      .select(:id, :content, :position, :knowledge_source_id)
      .order(Arel.sql("embedding <=> #{vector_sql}"))
      .limit(KNOWLEDGE_CHUNK_LIMIT)
      .to_a

    fit_knowledge_context(chunks)
  rescue RubyLLM::Error => error
    Rails.logger.warn("Vector knowledge search skipped: #{error.class} - #{error.message}")
    []
  rescue ActiveRecord::StatementInvalid => error
    Rails.logger.warn("Vector knowledge search unavailable: #{error.class} - #{error.message}")
    []
  end

  def relevant_keyword_chunks(agent, query)
    chunks = agent.knowledge_chunks
      .joins(:knowledge_source)
      .where(knowledge_sources: { status: "ready" })
      .select(:id, :content, :position, :knowledge_source_id)
      .to_a

    return [] if chunks.blank?

    query_terms = normalized_terms(query)
    scored_chunks = chunks.map do |chunk|
      content_terms = normalized_terms(chunk.content)
      score = (query_terms & content_terms).size
      [chunk, score]
    end

    selected_chunks = scored_chunks
      .select { |_chunk, score| score.positive? }
      .sort_by { |chunk, score| [-score, chunk.knowledge_source_id, chunk.position] }
      .map(&:first)

    selected_chunks = chunks.sort_by { |chunk| [chunk.knowledge_source_id, chunk.position] } if selected_chunks.blank?

    fit_knowledge_context(selected_chunks.first(KNOWLEDGE_CHUNK_LIMIT))
  end

  def fit_knowledge_context(chunks)
    selected_chunks = []
    used_chars = 0

    chunks.each do |chunk|
      content_size = chunk.content.to_s.length
      break if selected_chunks.any? && used_chars + content_size > KNOWLEDGE_CONTEXT_MAX_CHARS

      selected_chunks << chunk
      used_chars += content_size
    end

    selected_chunks
  end

  def normalized_terms(text)
    text.to_s
      .downcase
      .scan(/[[:alnum:]]{3,}/)
      .uniq
  end

  def set_cors_headers
    response.headers["Access-Control-Allow-Origin"] = request.origin if request.origin.present?
    response.headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    response.headers["Vary"] = "Origin"
  end

  def set_stream_headers
    set_cors_headers
    response.headers["Content-Type"] = "text/event-stream; charset=utf-8"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"
  end

  def write_sse(event, data)
    response.stream.write("event: #{event}\n")
    response.stream.write("data: #{data.to_json}\n\n")
  end
end
