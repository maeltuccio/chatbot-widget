class AddWidgetTitleVisibilityToAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :agents, :widget_show_title, :boolean, default: true, null: false
  end
end
