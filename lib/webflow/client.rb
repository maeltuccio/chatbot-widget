require "json"
require "net/http"
require "uri"

module Webflow
  class Client
    API_BASE_URL = "https://api.webflow.com/v2"
    OAUTH_AUTHORIZE_URL = "https://webflow.com/oauth/authorize"
    OAUTH_ACCESS_TOKEN_URL = "https://api.webflow.com/oauth/access_token"
    DEFAULT_LIMIT = 100

    class Error < StandardError; end

    def initialize(token:)
      @token = token
    end

    def self.authorization_url(client_id:, redirect_uri:, state:, scopes:)
      params = {
        response_type: "code",
        client_id: client_id,
        redirect_uri: redirect_uri,
        state: state,
        scope: scopes.join(" ")
      }

      query = URI.encode_www_form(params).gsub("+", "%20")
      "#{OAUTH_AUTHORIZE_URL}?#{query}"
    end

    def self.exchange_code(client_id:, client_secret:, code:, redirect_uri:)
      uri = URI(OAUTH_ACCESS_TOKEN_URL)
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(client_id, client_secret)
      request.set_form_data(
        grant_type: "authorization_code",
        client_id: client_id,
        client_secret: client_secret,
        code: code,
        redirect_uri: redirect_uri
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      payload = JSON.parse(response.body)
      return payload if response.is_a?(Net::HTTPSuccess)

      message = payload["message"].presence || payload["error"].presence || "Webflow OAuth returned HTTP #{response.code}"
      raise Error, message
    rescue JSON::ParserError
      raise Error, "Webflow OAuth returned an invalid JSON response"
    end

    def sites
      payload = get("/sites")
      payload.fetch("sites", payload.fetch("items", []))
    end

    def collections(site_id)
      payload = get("/sites/#{site_id}/collections")
      payload.fetch("collections", payload.fetch("items", []))
    end

    def collection_items(collection_id)
      items = []
      offset = 0

      loop do
        payload = get("/collections/#{collection_id}/items", limit: DEFAULT_LIMIT, offset: offset)
        page_items = payload.fetch("items", [])
        items.concat(page_items)

        pagination = payload.fetch("pagination", {})
        total = pagination.fetch("total", items.size)
        offset += page_items.size

        break if page_items.empty? || offset >= total
      end

      items
    end

    private

    attr_reader :token

    def get(path, params = {})
      uri = URI("#{API_BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params) if params.present?

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      parse_response(response)
    end

    def parse_response(response)
      payload = JSON.parse(response.body)

      return payload if response.is_a?(Net::HTTPSuccess)

      message = payload["message"].presence || "Webflow API returned HTTP #{response.code}"
      raise Error, message
    rescue JSON::ParserError
      raise Error, "Webflow API returned an invalid JSON response"
    end
  end
end
