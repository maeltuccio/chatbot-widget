require "csv"

class UsageController < ApplicationController
  before_action :require_manager!, only: :update_limits

  def index
    respond_to do |format|
      format.html { load_usage }
      format.csv do
        events = current_account.usage_events_this_month.includes(:agent).order(:created_at)
        send_data usage_csv(events),
          filename: "usage-#{Time.current.strftime("%Y-%m")}.csv",
          type: "text/csv; charset=utf-8"
      end
    end
  end

  def update_limits
    if current_account.update(usage_limit_params)
      redirect_to usage_path, notice: "Usage limits updated."
    else
      load_usage
      flash.now[:alert] = "Usage limits could not be updated."
      render :index, status: :unprocessable_entity
    end
  end

  private

  def load_usage
    @usage_events = current_account.usage_events_this_month.includes(:agent)
    @message_usage = @usage_events.where(event_type: "message")
    @embedding_usage = @usage_events.where(event_type: "embedding")
    @message_limit_remaining = remaining_usage(current_account.monthly_message_limit, @message_usage.count)
    @token_limit_remaining = remaining_usage(current_account.monthly_token_limit, @usage_events.sum(:total_tokens))
    @usage_by_agent = @usage_events
      .joins(:agent)
      .group("agents.name")
      .order(Arel.sql("COUNT(usage_events.id) DESC"))
      .count
    @tokens_by_agent = @usage_events
      .joins(:agent)
      .group("agents.name")
      .order(Arel.sql("SUM(usage_events.total_tokens) DESC"))
      .sum(:total_tokens)
    @recent_usage_events = @usage_events.order(created_at: :desc).limit(20)
  end

  def remaining_usage(limit, used)
    return if limit.blank?

    [limit - used, 0].max
  end

  def usage_limit_params
    params.require(:account).permit(:monthly_message_limit, :monthly_token_limit).tap do |permitted|
      permitted[:monthly_message_limit] = nil if permitted[:monthly_message_limit].blank?
      permitted[:monthly_token_limit] = nil if permitted[:monthly_token_limit].blank?
    end
  end

  def usage_csv(events)
    CSV.generate(headers: true) do |csv|
      csv << [
        "time",
        "agent",
        "type",
        "model",
        "input_tokens",
        "output_tokens",
        "total_tokens",
        "input_characters",
        "output_characters",
        "estimated_tokens"
      ]

      events.each do |event|
        csv << [
          event.created_at.iso8601,
          event.agent.name,
          event.event_type,
          event.model,
          event.input_tokens,
          event.output_tokens,
          event.total_tokens,
          event.input_characters,
          event.output_characters,
          event.metadata["estimated_tokens"] == true
        ]
      end
    end
  end
end
