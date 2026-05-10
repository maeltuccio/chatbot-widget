class CreateAgents < ActiveRecord::Migration[7.1]
  def change
    create_table :agents do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.string :public_token
      t.text :system_prompt
      t.text :welcome_message
      t.string :tone
      t.string :primary_goal
      t.boolean :active

      t.timestamps
    end
  end
end
