class AddUsageLimitsToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :monthly_message_limit, :integer
    add_column :accounts, :monthly_token_limit, :integer
  end
end
