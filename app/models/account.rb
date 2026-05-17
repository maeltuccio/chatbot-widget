class Account < ApplicationRecord
  has_many :agents
  has_many :users
  has_many :usage_events

  validates :monthly_message_limit, :monthly_token_limit,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 },
    allow_nil: true

  def usage_events_this_month
    usage_events.current_month
  end

  def message_usage_this_month
    usage_events_this_month.where(event_type: "message")
  end

  def messages_used_this_month
    message_usage_this_month.count
  end

  def tokens_used_this_month
    usage_events_this_month.sum(:total_tokens)
  end

  def monthly_message_limit_reached?
    monthly_message_limit.present? && messages_used_this_month >= monthly_message_limit
  end

  def monthly_token_limit_reached?
    monthly_token_limit.present? && tokens_used_this_month >= monthly_token_limit
  end

  def usage_limit_reached?
    monthly_message_limit_reached? || monthly_token_limit_reached?
  end

  def usage_limit_message
    if monthly_message_limit_reached?
      "Monthly AI reply limit reached for this workspace."
    elsif monthly_token_limit_reached?
      "Monthly token limit reached for this workspace."
    else
      "Usage limit reached for this workspace."
    end
  end
end
