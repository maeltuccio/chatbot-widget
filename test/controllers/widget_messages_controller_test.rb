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
    assert_equal "Monthly AI reply limit reached for this workspace.", response.parsed_body["error"]
  end
end
