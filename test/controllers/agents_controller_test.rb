require "test_helper"

class AgentsControllerTest < ActionDispatch::IntegrationTest
  test "destroy deletes agent and redirects to index" do
    agent = agents(:one)

    assert_difference("Agent.count", -1) do
      delete agent_url(agent)
    end

    assert_redirected_to agents_url
    assert_equal "Agent was successfully deleted.", flash[:notice]
  end
end
