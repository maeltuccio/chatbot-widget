require "action_view"
require "cgi"

module Webflow
  class CmsServicesImporter
    DEFAULT_SOURCE_TITLE = "Webflow Services"

    def initialize(agent:, collection_id:, client:, source_title: DEFAULT_SOURCE_TITLE, source: nil)
      @agent = agent
      @collection_id = collection_id
      @client = client
      @source_title = source_title
      @source = source
    end

    def call
      items = client.collection_items(collection_id)
      content = build_content(items)

      source = existing_source || agent.knowledge_sources.find_or_initialize_by(title: source_title)
      source.update!(
        title: source_title,
        source_type: "manual",
        status: "processing",
        raw_content: content
      )
      source.rebuild_chunks!
      source
    end

    private

    attr_reader :agent, :collection_id, :client, :source_title, :source

    def existing_source
      source
    end

    def build_content(items)
      content = items.map { |item| service_content(item) }.reject(&:blank?).join("\n\n")
      content.presence || "No Webflow services were found in the selected CMS collection."
    end

    def service_content(item)
      fields = item.fetch("fieldData", {})

      lines = []
      lines << "CMS item: #{fields["name"]}" if fields["name"].present?
      lines << "Slug: #{fields["slug"]}" if fields["slug"].present?
      lines << "Description courte: #{fields["short-description"]}" if fields["short-description"].present?
      lines << "Description longue: #{fields["long-description"]}" if fields["long-description"].present?
      lines << "Offre: #{strip_html(fields["body"])}" if fields["body"].present?
      lines << "Image principale: #{asset_url(fields["big-image"])}" if asset_url(fields["big-image"]).present?
      lines << "Miniature: #{asset_url(fields["thumbnail"])}" if asset_url(fields["thumbnail"]).present?

      lines.join("\n")
    end

    def strip_html(html)
      text = html.to_s.gsub(/<[^>]+>/, " ")
      CGI.unescapeHTML(ActionView::Base.full_sanitizer.sanitize(text)).squish
    end

    def asset_url(value)
      value["url"] if value.is_a?(Hash)
    end
  end
end
