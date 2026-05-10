class AddWidgetSettingsToAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :agents, :widget_title, :string
    add_column :agents, :widget_primary_color, :string
    add_column :agents, :widget_position, :string
    add_column :agents, :widget_send_label, :string
    add_column :agents, :widget_placeholder, :string
  end
end
