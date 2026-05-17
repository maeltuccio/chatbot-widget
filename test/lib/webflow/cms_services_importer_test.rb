require "test_helper"

module Webflow
  class CmsServicesImporterTest < ActiveSupport::TestCase
    FakeClient = Struct.new(:items) do
      def collection_items(_collection_id)
        items
      end
    end

    test "imports services into only the selected agent knowledge base" do
      agent = agents(:one)
      other_agent = agents(:two)

      importer = CmsServicesImporter.new(
        agent: agent,
        collection_id: "services",
        client: FakeClient.new([
          {
            "fieldData" => {
              "name" => "Installation de pompes à chaleur",
              "slug" => "installation-de-pompes-a-chaleur",
              "long-description" => "Solutions électriques pour systèmes de chauffage.",
              "body" => "<h2>Notre offre</h2><p>Analyse et mise en service.</p>",
              "thumbnail" => { "url" => "https://example.com/thumbnail.jpg" }
            }
          }
        ])
      )

      assert_difference -> { agent.knowledge_sources.count }, 1 do
        importer.call
      end

      source = agent.knowledge_sources.find_by!(title: "Webflow Services")
      assert_equal "ready", source.status
      assert_equal 1, source.knowledge_chunks.count
      assert_includes source.raw_content, "CMS item: Installation de pompes à chaleur"
      assert_includes source.raw_content, "Offre: Notre offre Analyse et mise en service."
      assert_not_includes source.raw_content, "<h2>"
      assert_equal 0, other_agent.knowledge_sources.where(title: "Webflow Services").count
    end
  end
end
