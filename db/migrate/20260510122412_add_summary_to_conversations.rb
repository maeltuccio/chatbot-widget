class AddSummaryToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :summary, :text
    add_column :conversations, :summarized_until_message_id, :bigint
    add_index :conversations, :summarized_until_message_id
  end
end
