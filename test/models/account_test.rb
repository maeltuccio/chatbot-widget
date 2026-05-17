require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "tracks monthly message and token limit state" do
    account = accounts(:one)
    agent = agents(:one)

    account.update!(monthly_message_limit: 1, monthly_token_limit: 20)
    UsageEvent.create!(
      account: account,
      agent: agent,
      event_type: "message",
      input_tokens: 6,
      output_tokens: 14,
      input_characters: 24,
      output_characters: 56
    )

    assert_equal 1, account.messages_used_this_month
    assert_equal 20, account.tokens_used_this_month
    assert account.monthly_message_limit_reached?
    assert account.monthly_token_limit_reached?
    assert account.usage_limit_reached?
  end

  test "allows blank usage limits" do
    account = accounts(:one)

    account.monthly_message_limit = nil
    account.monthly_token_limit = nil

    assert account.valid?
    refute account.usage_limit_reached?
  end
end
