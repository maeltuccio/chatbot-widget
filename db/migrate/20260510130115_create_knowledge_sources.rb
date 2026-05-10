class CreateKnowledgeSources < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_sources do |t|
      t.references :agent, null: false, foreign_key: true
      t.string :source_type, null: false, default: "manual"
      t.string :title, null: false
      t.string :url
      t.string :status, null: false, default: "draft"
      t.text :raw_content

      t.timestamps
    end

    add_index :knowledge_sources, [:agent_id, :status]
    add_index :knowledge_sources, [:agent_id, :source_type]
  end
end
