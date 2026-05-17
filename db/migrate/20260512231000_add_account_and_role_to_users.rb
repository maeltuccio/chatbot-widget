class AddAccountAndRoleToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :account, foreign_key: true
    add_column :users, :role, :string, null: false, default: "member"
    add_index :users, [:account_id, :role]
  end
end
