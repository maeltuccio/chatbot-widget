class KnowledgeSourcesController < ApplicationController
  before_action :set_agent
  before_action :set_knowledge_source, only: [:show, :edit, :update, :destroy]

  def index
    @knowledge_sources = @agent.knowledge_sources
      .includes(:knowledge_chunks)
      .order(updated_at: :desc)
  end

  def show
    @knowledge_chunks = @knowledge_source.knowledge_chunks.order(:position)
  end

  def new
    @knowledge_source = @agent.knowledge_sources.new(source_type: "manual", status: "draft")
  end

  def create
    @knowledge_source = @agent.knowledge_sources.new(knowledge_source_params)
    @knowledge_source.source_type = "manual"
    @knowledge_source.status = "draft"

    if @knowledge_source.save
      @knowledge_source.rebuild_chunks!
      redirect_to agent_knowledge_source_path(@agent, @knowledge_source), notice: "Knowledge source was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @knowledge_source.update(knowledge_source_params)
      @knowledge_source.rebuild_chunks!
      redirect_to agent_knowledge_source_path(@agent, @knowledge_source), notice: "Knowledge source was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @knowledge_source.destroy!
    redirect_to agent_knowledge_sources_path(@agent), notice: "Knowledge source was successfully deleted."
  end

  private

  def set_agent
    @agent = Agent.find(params[:agent_id])
  end

  def set_knowledge_source
    @knowledge_source = @agent.knowledge_sources.find(params[:id])
  end

  def knowledge_source_params
    params.require(:knowledge_source).permit(:title, :raw_content)
  end
end
