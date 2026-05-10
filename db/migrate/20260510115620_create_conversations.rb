class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :agent, null: false, foreign_key: true
      t.string :public_token, null: false
      t.string :visitor_identifier
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :conversations, :public_token, unique: true
    add_index :conversations, [:agent_id, :last_message_at]
  end
end
