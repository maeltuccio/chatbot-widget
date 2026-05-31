class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  WIDGET_MESSAGE_PATHS = %w[
    /widget/messages
    /widget/messages/stream
  ].freeze

  throttle("login attempts by ip", limit: 10, period: 1.minute) do |request|
    request.ip if request.post? && request.path == "/users/sign_in"
  end

  throttle("signup attempts by ip", limit: 5, period: 10.minutes) do |request|
    request.ip if request.post? && request.path == "/users"
  end

  throttle("widget config by ip", limit: 120, period: 1.minute) do |request|
    request.ip if request.get? && request.path.start_with?("/widget/agents/")
  end

  throttle("widget messages by ip", limit: 30, period: 1.minute) do |request|
    request.ip if request.post? && WIDGET_MESSAGE_PATHS.include?(request.path)
  end

  throttle("widget messages by conversation", limit: 8, period: 5.minutes) do |request|
    next unless request.post? && WIDGET_MESSAGE_PATHS.include?(request.path)

    token = request.params["conversation_token"].presence
    "#{request.params["agent_token"]}:#{token}" if token.present?
  end

  throttle("widget messages by visitor", limit: 12, period: 10.minutes) do |request|
    next unless request.post? && WIDGET_MESSAGE_PATHS.include?(request.path)

    visitor_identifier = request.params["visitor_identifier"].presence
    "#{request.params["agent_token"]}:#{visitor_identifier}" if visitor_identifier.present?
  end

  throttle("widget messages by agent", limit: 300, period: 1.hour) do |request|
    next unless request.post? && WIDGET_MESSAGE_PATHS.include?(request.path)

    request.params["agent_token"].presence
  end

  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after.to_s
    }

    [
      429,
      headers,
      [{ error: "Trop de requêtes. Veuillez réessayer dans un instant." }.to_json]
    ]
  end
end
