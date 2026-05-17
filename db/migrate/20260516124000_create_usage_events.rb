class CreateUsageEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :usage_events do |t|
      t.references :account, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.string :event_type, null: false
      t.string :model
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.integer :total_tokens, null: false, default: 0
      t.integer :input_characters, null: false, default: 0
      t.integer :output_characters, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :usage_events, [:account_id, :event_type, :created_at]
    add_index :usage_events, [:agent_id, :event_type, :created_at]
  end
end
