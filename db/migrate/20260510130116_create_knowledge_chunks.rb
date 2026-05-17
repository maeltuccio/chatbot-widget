class CreateKnowledgeChunks < ActiveRecord::Migration[7.1]
  EMBEDDING_DIMENSIONS = 1536

  def change
    create_table :knowledge_chunks do |t|
      t.references :agent, null: false, foreign_key: true
      t.references :knowledge_source, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :position, null: false
      t.string :embedding_model, null: false, default: "text-embedding-3-small"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :knowledge_chunks, [:agent_id, :knowledge_source_id]
    add_index :knowledge_chunks, [:knowledge_source_id, :position], unique: true

    if extension_enabled?("vector")
      execute "ALTER TABLE knowledge_chunks ADD COLUMN embedding vector(#{EMBEDDING_DIMENSIONS})"
      add_index :knowledge_chunks,
        :embedding,
        using: :hnsw,
        opclass: :vector_cosine_ops
    end
  end
end
