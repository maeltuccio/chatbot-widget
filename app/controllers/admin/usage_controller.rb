class Admin::UsageController < ApplicationController
  before_action :require_platform_admin!

  def index
    load_usage_board
  end

  def update_limits
    account = Account.find(params[:account_id])

    if account.update(usage_limit_params)
      redirect_to admin_usage_path, notice: "Les limites de #{account.name} ont été mises à jour."
    else
      load_usage_board
      flash.now[:alert] = "Les limites de #{account.name} n'ont pas pu être mises à jour."
      render :index, status: :unprocessable_entity
    end
  end

  private

  def load_usage_board
    accounts = Account.includes(:users).left_joins(:agents).group("accounts.id").order(:name)
    message_counts = UsageEvent.current_month.where(event_type: "message").group(:account_id).count
    embedding_counts = UsageEvent.current_month.where(event_type: "embedding").group(:account_id).count
    token_totals = UsageEvent.current_month.group(:account_id).sum(:total_tokens)
    agent_counts = Agent.group(:account_id).count

    @account_usage_cards = accounts.map do |account|
      messages_used = message_counts[account.id].to_i
      tokens_used = token_totals[account.id].to_i
      message_percent = usage_percent(messages_used, account.monthly_message_limit)
      token_percent = usage_percent(tokens_used, account.monthly_token_limit)

      {
        account: account,
        agents_count: agent_counts[account.id].to_i,
        users_count: account.users.size,
        messages_used: messages_used,
        embeddings_used: embedding_counts[account.id].to_i,
        tokens_used: tokens_used,
        message_percent: message_percent,
        token_percent: token_percent,
        status: usage_status([message_percent, token_percent].compact.max)
      }
    end

    @total_accounts = @account_usage_cards.size
    @total_messages = @account_usage_cards.sum { |card| card[:messages_used] }
    @total_embeddings = @account_usage_cards.sum { |card| card[:embeddings_used] }
    @total_tokens = @account_usage_cards.sum { |card| card[:tokens_used] }
  end

  def usage_percent(used, limit)
    return if limit.blank?
    return 100 if limit.zero? && used.positive?
    return 0 if limit.zero?

    ((used.to_f / limit) * 100).round.clamp(0, 100)
  end

  def usage_status(percent)
    return "unlimited" if percent.blank?
    return "danger" if percent >= 100
    return "warning" if percent >= 80

    "success"
  end

  def usage_limit_params
    params.require(:account).permit(:monthly_message_limit, :monthly_token_limit).tap do |permitted|
      permitted[:monthly_message_limit] = nil if permitted[:monthly_message_limit].blank?
      permitted[:monthly_token_limit] = nil if permitted[:monthly_token_limit].blank?
    end
  end
end
