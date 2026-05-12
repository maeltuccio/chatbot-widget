class WebflowConnectionsController < ApplicationController
  WEBFLOW_SCOPES = %w[sites:read cms:read].freeze

  before_action :set_agent, except: :callback
  before_action :set_connection, only: [:show, :update, :sync, :destroy]

  def show
    @sites = []
    @collections = []

    if @connection.present?
      client = webflow_client
      @sites = client.sites
      @collections = client.collections(@connection.site_id) if @connection.site_id.present?
    end
  rescue Webflow::Client::Error => error
    flash.now[:alert] = "Webflow is connected, but the API could not be read: #{error.message}"
  end

  def connect
    ensure_oauth_configured!

    state = SecureRandom.hex(24)
    session[:webflow_oauth_state] = state
    session[:webflow_oauth_agent_id] = @agent.id

    redirect_to Webflow::Client.authorization_url(
      client_id: ENV.fetch("WEBFLOW_CLIENT_ID"),
      redirect_uri: webflow_redirect_uri,
      state: state,
      scopes: WEBFLOW_SCOPES
    ), allow_other_host: true
  rescue KeyError
    redirect_to agent_path(@agent), alert: "WEBFLOW_CLIENT_ID and WEBFLOW_CLIENT_SECRET must be configured first."
  end

  def callback
    @agent = Agent.find(session[:webflow_oauth_agent_id])

    unless valid_oauth_state?
      redirect_to agent_path(@agent), alert: "Webflow connection could not be verified. Please try again."
      return
    end

    payload = Webflow::Client.exchange_code(
      client_id: ENV.fetch("WEBFLOW_CLIENT_ID"),
      client_secret: ENV.fetch("WEBFLOW_CLIENT_SECRET"),
      code: params.fetch(:code),
      redirect_uri: webflow_redirect_uri
    )

    connection = @agent.webflow_connection || @agent.build_webflow_connection
    connection.access_token = payload.fetch("access_token")
    connection.scope = payload["scope"]
    connection.status = "connected"
    connection.save!

    clear_oauth_state
    redirect_to agent_webflow_connection_path(@agent), notice: "Webflow connected. Choose the CMS collection to sync."
  rescue KeyError
    redirect_to agent_path(@agent), alert: "Webflow did not return the expected OAuth data."
  rescue ActiveRecord::RecordNotFound
    redirect_to agents_path, alert: "Webflow connection expired. Please start again from the agent."
  rescue Webflow::Client::Error => error
    redirect_to agent_path(@agent), alert: "Webflow connection failed: #{error.message}"
  end

  def update
    site = webflow_client.sites.find { |candidate| candidate["id"] == webflow_params[:site_id] }
    collections = webflow_params[:site_id].present? ? webflow_client.collections(webflow_params[:site_id]) : []
    collection = collections.find { |candidate| candidate["id"] == webflow_params[:collection_id] }

    @connection.update!(
      site_id: webflow_params[:site_id],
      site_name: site&.dig("displayName") || site&.dig("name"),
      collection_id: webflow_params[:collection_id],
      collection_name: collection&.dig("displayName") || collection&.dig("name") || collection&.dig("slug"),
      status: collection.present? ? "configured" : "connected"
    )

    message = collection.present? ? "Webflow collection saved." : "Webflow site saved. Choose the CMS collection to sync."
    redirect_to agent_webflow_connection_path(@agent), notice: message
  rescue Webflow::Client::Error => error
    redirect_to agent_webflow_connection_path(@agent), alert: "Could not save Webflow collection: #{error.message}"
  end

  def sync
    unless @connection.syncable?
      redirect_to agent_webflow_connection_path(@agent), alert: "Choose a Webflow site and collection before syncing."
      return
    end

    source = Webflow::CmsServicesImporter.new(
      agent: @agent,
      collection_id: @connection.collection_id,
      client: webflow_client,
      source_title: "Webflow Services"
    ).call

    @connection.update!(
      last_synced_at: Time.current,
      metadata: @connection.metadata.merge(
        "last_source_id" => source.id,
        "last_chunk_count" => source.knowledge_chunks.count
      )
    )

    redirect_to agent_path(@agent), notice: "Webflow services synced into this agent."
  rescue Webflow::Client::Error => error
    @connection.update(status: "failed") if @connection.present?
    redirect_to agent_webflow_connection_path(@agent), alert: "Webflow sync failed: #{error.message}"
  end

  def destroy
    @connection&.destroy!
    redirect_to agent_path(@agent), notice: "Webflow disconnected from this agent."
  end

  private

  def set_agent
    @agent = Agent.find(params[:agent_id])
  end

  def set_connection
    @connection = @agent.webflow_connection
  end

  def webflow_client
    Webflow::Client.new(token: @connection.access_token)
  end

  def webflow_params
    params.require(:webflow_connection).permit(:site_id, :collection_id)
  end

  def valid_oauth_state?
    params[:state].present? &&
      session[:webflow_oauth_state] == params[:state] &&
      session[:webflow_oauth_agent_id] == @agent.id
  end

  def clear_oauth_state
    session.delete(:webflow_oauth_state)
    session.delete(:webflow_oauth_agent_id)
  end

  def ensure_oauth_configured!
    ENV.fetch("WEBFLOW_CLIENT_ID")
    ENV.fetch("WEBFLOW_CLIENT_SECRET")
  end

  def webflow_redirect_uri
    return webflow_oauth_callback_url if ENV["APP_HOST"].blank?

    "#{ENV.fetch("APP_HOST").chomp("/")}/webflow/oauth/callback"
  end
end
