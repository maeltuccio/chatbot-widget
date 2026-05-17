class RemoveConfirmableFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, :confirmation_token, if_exists: true
    remove_column :users, :confirmation_token, :string, if_exists: true
    remove_column :users, :confirmed_at, :datetime, if_exists: true
    remove_column :users, :confirmation_sent_at, :datetime, if_exists: true
    remove_column :users, :unconfirmed_email, :string, if_exists: true
  end
end
