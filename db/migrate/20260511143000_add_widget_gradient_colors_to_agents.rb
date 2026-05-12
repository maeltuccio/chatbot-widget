class AddWidgetGradientColorsToAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :agents, :widget_gradient_colors, :text
  end
end
