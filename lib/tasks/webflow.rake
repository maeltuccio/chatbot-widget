namespace :webflow do
  desc "Import Webflow service CMS items into one agent knowledge source"
  task import_services: :environment do
    token = ENV.fetch("WEBFLOW_API_TOKEN")
    collection_id = ENV.fetch("WEBFLOW_SERVICES_COLLECTION_ID")
    agent_token = ENV["AGENT_PUBLIC_TOKEN"].presence || ENV.fetch("AGENT_TOKEN")
    source_title = ENV["WEBFLOW_SERVICES_SOURCE_TITLE"].presence || Webflow::CmsServicesImporter::DEFAULT_SOURCE_TITLE

    agent = Agent.find_by!(public_token: agent_token)
    client = Webflow::Client.new(token: token)
    source = Webflow::CmsServicesImporter.new(
      agent: agent,
      collection_id: collection_id,
      client: client,
      source_title: source_title
    ).call

    puts "Imported #{source.knowledge_chunks.count} knowledge chunks into #{agent.name} (#{agent.public_token})."
  end
end
