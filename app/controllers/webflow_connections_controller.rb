class WebflowConnectionsController < ApplicationController
  WEBFLOW_SCOPES = %w[sites:read cms:read].freeze

  before_action :require_manager!, except: :callback
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
    flash.now[:alert] = "Webflow est connecté, mais l'API n'a pas pu être lue : #{error.message}"
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
    redirect_to agent_path(@agent), alert: "WEBFLOW_CLIENT_ID et WEBFLOW_CLIENT_SECRET doivent d'abord être configurés."
  end

  def callback
    @agent = current_account.agents.find(session[:webflow_oauth_agent_id])

    unless valid_oauth_state?
      redirect_to agent_path(@agent), alert: "La connexion Webflow n'a pas pu être vérifiée. Veuillez réessayer."
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
    redirect_to agent_webflow_connection_path(@agent), notice: "Webflow est connecté. Choisissez la collection CMS à synchroniser."
  rescue KeyError
    redirect_to agent_path(@agent), alert: "Webflow n'a pas renvoyé les données OAuth attendues."
  rescue ActiveRecord::RecordNotFound
    redirect_to agents_path, alert: "La connexion Webflow a expiré. Veuillez recommencer depuis l'agent."
  rescue Webflow::Client::Error => error
    redirect_to agent_path(@agent), alert: "La connexion Webflow a échoué : #{error.message}"
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

    message = collection.present? ? "La collection Webflow a été enregistrée." : "Le site Webflow a été enregistré. Choisissez la collection CMS à synchroniser."
    redirect_to agent_webflow_connection_path(@agent), notice: message
  rescue Webflow::Client::Error => error
    redirect_to agent_webflow_connection_path(@agent), alert: "Impossible d'enregistrer la collection Webflow : #{error.message}"
  end

  def sync
    unless @connection.syncable?
      redirect_to agent_webflow_connection_path(@agent), alert: "Choisissez un site et une collection Webflow avant de synchroniser."
      return
    end

    source = Webflow::CmsServicesImporter.new(
      agent: @agent,
      collection_id: @connection.collection_id,
      client: webflow_client,
      source_title: webflow_source_title,
      source: existing_webflow_source
    ).call

    @connection.update!(
      last_synced_at: Time.current,
      metadata: @connection.metadata.merge(
        "last_source_id" => source.id,
        "last_chunk_count" => source.knowledge_chunks.count
      )
    )

    redirect_to agent_path(@agent), notice: "Les services Webflow ont été synchronisés dans cet agent."
  rescue Webflow::Client::Error => error
    @connection.update(status: "failed") if @connection.present?
    redirect_to agent_webflow_connection_path(@agent), alert: "La synchronisation Webflow a échoué : #{error.message}"
  end

  def destroy
    @connection&.destroy!
    redirect_to agent_path(@agent), notice: "Webflow a été déconnecté de cet agent."
  end

  private

  def set_agent
    @agent = current_account.agents.find(params[:agent_id])
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

  def webflow_source_title
    name = @connection.collection_name.presence || @connection.collection_id
    "Webflow - #{name}"
  end

  def existing_webflow_source
    source_id = @connection.metadata["last_source_id"]
    @agent.knowledge_sources.find_by(id: source_id) ||
      @agent.knowledge_sources.find_by(title: "Webflow Services")
  end
end
