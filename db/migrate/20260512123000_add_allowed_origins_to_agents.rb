class AddAllowedOriginsToAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :agents, :allowed_origins, :text
  end
end
