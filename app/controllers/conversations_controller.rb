class ConversationsController < ApplicationController
  before_action :set_agent
  before_action :set_conversation, only: :show

  def index
    @conversations = @agent.conversations
      .includes(:messages)
      .order(last_message_at: :desc, created_at: :desc)
  end

  def show
    @messages = @conversation.messages.order(:created_at)
  end

  private

  def set_agent
    @agent = current_account.agents.find(params[:agent_id])
  end

  def set_conversation
    @conversation = @agent.conversations.find(params[:id])
  end
end
