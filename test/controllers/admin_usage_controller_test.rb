require "test_helper"

class AdminUsageControllerTest < ActionDispatch::IntegrationTest
  test "platform admin can view every client usage board" do
    account = accounts(:two)
    account.update!(name: "Client B", owner_email: "client-b@example.com")
    UsageEvent.create!(
      account: account,
      agent: agents(:two),
      event_type: "message",
      model: "gpt-4o-mini",
      input_tokens: 25,
      output_tokens: 35,
      input_characters: 100,
      output_characters: 140,
      metadata: { estimated_tokens: false }
    )
    sign_in users(:one)

    get admin_usage_url

    assert_response :success
    assert_includes response.body, "Consommation clients"
    assert_includes response.body, "Client B"
    assert_includes response.body, "client-b@example.com"
    assert_includes response.body, "60"
  end

  test "member cannot access client usage board" do
    sign_in users(:two)

    get admin_usage_url

    assert_redirected_to agents_url
  end

  test "workspace owner without platform admin cannot access client usage board" do
    user = users(:one)
    user.update!(platform_admin: false)
    sign_in user

    get admin_usage_url

    assert_redirected_to agents_url
  end

  test "workspace owner without platform admin cannot update client limits" do
    user = users(:one)
    user.update!(platform_admin: false)
    account = accounts(:two)
    account.update!(monthly_message_limit: 10, monthly_token_limit: 100)
    sign_in user

    patch admin_usage_account_limits_url(account), params: {
      account: {
        monthly_message_limit: 750,
        monthly_token_limit: 120_000
      }
    }

    assert_redirected_to agents_url
    assert_equal 10, account.reload.monthly_message_limit
    assert_equal 100, account.monthly_token_limit
  end

  test "platform admin can update any client limits from board" do
    account = accounts(:two)
    sign_in users(:one)

    patch admin_usage_account_limits_url(account), params: {
      account: {
        monthly_message_limit: 750,
        monthly_token_limit: 120_000
      }
    }

    assert_redirected_to admin_usage_url
    assert_equal 750, account.reload.monthly_message_limit
    assert_equal 120_000, account.monthly_token_limit
  end
end
