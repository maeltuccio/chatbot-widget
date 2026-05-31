require "test_helper"

class WidgetMessagesControllerTest < ActionDispatch::IntegrationTest
  test "blocks widget messages when monthly message limit is reached" do
    account = accounts(:one)
    agent = agents(:one)
    account.update!(monthly_message_limit: 0)
    agent.update!(active: true, allowed_origins: "https://example.com")

    assert_no_difference "Conversation.count" do
      post "/widget/messages",
        params: {
          agent_token: agent.public_token,
          message: "Hello"
        },
        headers: {
          "Origin" => "https://example.com"
        }
    end

    assert_response :payment_required
    assert_equal "La limite mensuelle de réponses IA est atteinte pour cet espace de travail.", response.parsed_body["error"]
  end

  test "blocks widget messages when session message limit is reached" do
    agent = agents(:one)
    agent.update!(active: true, allowed_origins: "https://example.com")
    conversation = agent.conversations.create!(public_token: "session_limit_token")

    WidgetMessagesController::SESSION_MESSAGE_LIMIT.times do |index|
      conversation.messages.create!(role: "visitor", content: "Message #{index}")
    end

    assert_no_difference "Message.count" do
      post "/widget/messages",
        params: {
          agent_token: agent.public_token,
          conversation_token: conversation.public_token,
          message: "Hello"
        },
        headers: {
          "Origin" => "https://example.com"
        }
    end

    assert_response :too_many_requests
    assert_equal "La limite de messages pour cette conversation est atteinte.", response.parsed_body["error"]
    assert_equal conversation.public_token, response.parsed_body["conversation_token"]
  end

  test "allows backoffice playground messages beyond session message limit" do
    agent = agents(:one)
    conversation = agent.conversations.create!(public_token: "backoffice_session_limit_token")
    sign_in users(:one)

    WidgetMessagesController::SESSION_MESSAGE_LIMIT.times do |index|
      conversation.messages.create!(role: "visitor", content: "Message #{index}")
    end

    assert_difference "Message.count", 1 do
      post "/widget/messages",
        params: {
          agent_token: agent.public_token,
          conversation_token: conversation.public_token,
          message: "Hello"
        },
        headers: {
          "Referer" => playground_agent_url(agent)
        }
    end

    assert_response :service_unavailable
    assert_equal "OPENAI_API_KEY n'est pas configurée.", response.parsed_body["error"]
  end

  test "blocks widget messages that are too long" do
    agent = agents(:one)
    agent.update!(active: true, allowed_origins: "https://example.com")

    assert_no_difference "Conversation.count" do
      post "/widget/messages",
        params: {
          agent_token: agent.public_token,
          message: "x" * (WidgetMessagesController::MESSAGE_MAX_CHARS + 1)
        },
        headers: {
          "Origin" => "https://example.com"
        }
    end

    assert_response :unprocessable_entity
    assert_equal "Le message est trop long. Limite actuelle : #{WidgetMessagesController::MESSAGE_MAX_CHARS} caractères.", response.parsed_body["error"]
  end
end
