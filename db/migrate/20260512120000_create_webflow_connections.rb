class CreateWebflowConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :webflow_connections do |t|
      t.references :agent, null: false, foreign_key: true, index: { unique: true }
      t.text :access_token_ciphertext, null: false
      t.string :scope
      t.string :status, null: false, default: "connected"
      t.string :site_id
      t.string :site_name
      t.string :collection_id
      t.string :collection_name
      t.datetime :last_synced_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :webflow_connections, :status
  end
end
