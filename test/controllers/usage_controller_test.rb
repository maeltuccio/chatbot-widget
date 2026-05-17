require "test_helper"
require "csv"

class UsageControllerTest < ActionDispatch::IntegrationTest
  test "manager can update workspace usage limits" do
    sign_in users(:one)

    patch usage_limits_url, params: {
      account: {
        monthly_message_limit: 250,
        monthly_token_limit: 50_000
      }
    }

    assert_redirected_to usage_url
    assert_equal 250, accounts(:one).reload.monthly_message_limit
    assert_equal 50_000, accounts(:one).monthly_token_limit
  end

  test "blank limits are saved as unlimited" do
    account = accounts(:one)
    account.update!(monthly_message_limit: 10, monthly_token_limit: 100)
    sign_in users(:one)

    patch usage_limits_url, params: {
      account: {
        monthly_message_limit: "",
        monthly_token_limit: ""
      }
    }

    assert_redirected_to usage_url
    assert_nil account.reload.monthly_message_limit
    assert_nil account.monthly_token_limit
  end

  test "exports current month billable usage as csv" do
    account = accounts(:one)
    agent = agents(:one)
    UsageEvent.create!(
      account: account,
      agent: agent,
      event_type: "message",
      model: "gpt-4o-mini",
      input_tokens: 10,
      output_tokens: 20,
      input_characters: 40,
      output_characters: 80,
      metadata: { estimated_tokens: false }
    )
    sign_in users(:one)

    get usage_url(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    csv = CSV.parse(response.body, headers: true)
    assert_equal 1, csv.length
    assert_equal agent.name, csv.first["agent"]
    assert_equal "message", csv.first["type"]
    assert_equal "gpt-4o-mini", csv.first["model"]
    assert_equal "30", csv.first["total_tokens"]
  end
end
