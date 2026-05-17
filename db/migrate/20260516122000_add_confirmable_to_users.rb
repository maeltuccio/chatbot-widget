class AddConfirmableToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string

    add_index :users, :confirmation_token, unique: true

    execute "UPDATE users SET confirmed_at = CURRENT_TIMESTAMP"
  end

  def down
    remove_index :users, :confirmation_token, if_exists: true
    remove_column :users, :confirmation_token, :string, if_exists: true
    remove_column :users, :confirmed_at, :datetime, if_exists: true
    remove_column :users, :confirmation_sent_at, :datetime, if_exists: true
    remove_column :users, :unconfirmed_email, :string, if_exists: true
  end
end
