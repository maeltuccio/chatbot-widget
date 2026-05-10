class AgentsController < ApplicationController
  before_action :set_agent, only: [:show, :edit, :update]

  def index
    @agents = Agent.order(created_at: :desc)
  end

  def show
  end

  def new
    @agent = Agent.new(active: true)
  end

  def create
    @agent = default_account.agents.new(agent_params)

    if @agent.save
      redirect_to @agent, notice: "Agent was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @agent.update(agent_params)
      redirect_to @agent, notice: "Agent was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_agent
    @agent = Agent.find(params[:id])
  end

  def agent_params
    params.require(:agent).permit(
      :name,
      :system_prompt,
      :welcome_message,
      :tone,
      :primary_goal,
      :active,
      :widget_title,
      :widget_primary_color,
      :widget_position,
      :widget_send_label,
      :widget_placeholder
    )
  end

  def default_account
    Account.first || Account.create!(
      name: "Demo Account",
      plan: "demo",
      owner_email: "demo@example.com"
    )
  end
end
