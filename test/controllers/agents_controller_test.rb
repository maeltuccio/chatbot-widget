require "test_helper"

class AgentsControllerTest < ActionDispatch::IntegrationTest
  test "edit renders an embedded chatbot playground" do
    agent = agents(:one)
    sign_in users(:one)

    get edit_agent_url(agent)

    assert_response :success
    assert_includes response.body, playground_agent_path(agent)
    assert_includes response.body, "chatbot-playground-frame"
  end

  test "playground renders the auto opened widget script" do
    agent = agents(:one)
    sign_in users(:one)

    get playground_agent_url(agent)

    assert_response :success
    assert_includes response.body, %(data-agent-token="#{agent.public_token}")
    assert_includes response.body, %(data-open="true")
    refute_includes response.body, "backoffice-shell"
    refute_includes response.body, "app-sidebar"
  end

  test "playground can load inactive agent config for the owning account" do
    agent = agents(:one)
    sign_in users(:one)

    get "/widget/agents/#{agent.public_token}", headers: { "Referer" => playground_agent_url(agent) }

    assert_response :success
    assert_equal agent.name, response.parsed_body["name"]
  end

  test "update from editor renders edit without redirecting" do
    agent = agents(:one)
    sign_in users(:one)

    patch edit_agent_url(agent), params: {
      agent: {
        name: "Updated agent",
        system_prompt: agent.system_prompt,
        welcome_message: agent.welcome_message,
        tone: agent.tone,
        primary_goal: agent.primary_goal,
        active: agent.active,
        widget_title: agent.widget_title,
        widget_primary_color: agent.widget_primary_color,
        widget_position: agent.widget_position,
        widget_theme: agent.widget_theme,
        widget_show_title: agent.widget_show_title,
        widget_send_label: agent.widget_send_label,
        widget_placeholder: agent.widget_placeholder,
        allowed_origins: agent.allowed_origins
      }
    }

    assert_response :success
    assert_includes response.body, "Updated agent"
    assert_includes response.body, "chatbot-playground-frame"
  end

  test "ajax preview update returns playground url" do
    agent = agents(:one)
    sign_in users(:one)

    patch edit_agent_url(agent, format: :json), params: {
      agent: {
        name: "Preview agent",
        system_prompt: agent.system_prompt,
        welcome_message: agent.welcome_message,
        tone: agent.tone,
        primary_goal: agent.primary_goal,
        active: agent.active,
        widget_title: agent.widget_title,
        widget_primary_color: agent.widget_primary_color,
        widget_position: agent.widget_position,
        widget_theme: "dark",
        widget_show_title: agent.widget_show_title,
        widget_send_label: agent.widget_send_label,
        widget_placeholder: agent.widget_placeholder,
        allowed_origins: agent.allowed_origins
      }
    }

    assert_response :success
    assert_equal "Chatbot preview updated.", response.parsed_body["message"]
    assert_equal playground_agent_path(agent), response.parsed_body["playground_url"]
    assert_equal "dark", response.parsed_body["widget_theme"]
    assert_equal "dark", agent.reload.widget_theme
  end

  test "destroy deletes agent and redirects to index" do
    agent = agents(:one)
    sign_in users(:one)

    assert_difference("Agent.count", -1) do
      delete agent_url(agent)
    end

    assert_redirected_to agents_url
    assert_equal "Agent was successfully deleted.", flash[:notice]
  end
end
