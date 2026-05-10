RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.default_model = ENV.fetch("OPENAI_MODEL", "gpt-4.1-mini")
  config.request_timeout = Rails.env.production? ? 60 : 30
  config.logger = Rails.logger
end
