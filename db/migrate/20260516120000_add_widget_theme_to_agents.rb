class AddWidgetThemeToAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :agents, :widget_theme, :string
  end
end
