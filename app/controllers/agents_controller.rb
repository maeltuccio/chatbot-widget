class AgentsController < ApplicationController
  before_action :require_manager!, except: [:index, :show]
  before_action :set_agent, only: [:show, :playground, :edit, :update, :destroy]

  def index
    @agents = current_account.agents.order(created_at: :desc)
  end

  def show
  end

  def playground
    render layout: false
  end

  def new
    @agent = Agent.new(active: true)
  end

  def create
    @agent = current_account.agents.new(agent_params)

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
      respond_to do |format|
        format.html do
          flash.now[:notice] = "Agent was successfully updated."
          render :edit, status: :ok
        end

        format.json do
          render json: {
            message: "Chatbot preview updated.",
            playground_url: playground_agent_path(@agent),
            widget_theme: @agent.widget_theme
          }
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json do
          render json: {
            errors: @agent.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @agent.destroy!
    redirect_to agents_path, notice: "Agent was successfully deleted."
  end

  private

  def set_agent
    @agent = current_account.agents.find(params[:id])
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
      :widget_theme,
      :widget_show_title,
      :widget_send_label,
      :widget_placeholder,
      :allowed_origins
    )
  end

end
