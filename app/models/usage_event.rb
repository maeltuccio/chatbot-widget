class UsageEvent < ApplicationRecord
  EVENT_TYPES = %w[message embedding].freeze

  belongs_to :account
  belongs_to :agent
  belongs_to :conversation, optional: true

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :input_tokens, :output_tokens, :total_tokens, :input_characters, :output_characters,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :set_total_tokens

  scope :current_month, -> { where(created_at: Time.current.all_month) }

  def self.record_message!(agent:, conversation:, input_text:, output_text:, response:)
    input_tokens = token_value(response, :input_tokens)
    output_tokens = token_value(response, :output_tokens)

    create!(
      account: agent.account,
      agent: agent,
      conversation: conversation,
      event_type: "message",
      model: response_model(response),
      input_tokens: input_tokens || estimated_tokens(input_text),
      output_tokens: output_tokens || estimated_tokens(output_text),
      input_characters: input_text.to_s.length,
      output_characters: output_text.to_s.length,
      metadata: {
        estimated_tokens: input_tokens.blank? || output_tokens.blank?
      }
    )
  end

  def self.record_embedding!(agent:, knowledge_source:, content:, embedding:)
    create!(
      account: agent.account,
      agent: agent,
      event_type: "embedding",
      model: KnowledgeChunk::EMBEDDING_MODEL,
      input_tokens: token_value(embedding, :input_tokens) || estimated_tokens(content),
      input_characters: content.to_s.length,
      metadata: {
        knowledge_source_id: knowledge_source.id,
        estimated_tokens: token_value(embedding, :input_tokens).blank?
      }
    )
  end

  def self.estimated_tokens(text)
    (text.to_s.length / 4.0).ceil
  end

  def self.token_value(response, method_name)
    return unless response.respond_to?(method_name)

    response.public_send(method_name)&.to_i
  end

  def self.response_model(response)
    return response.model_id if response.respond_to?(:model_id)
    return response.model if response.respond_to?(:model)
  end

  private

  def set_total_tokens
    self.total_tokens = input_tokens.to_i + output_tokens.to_i
  end
end
