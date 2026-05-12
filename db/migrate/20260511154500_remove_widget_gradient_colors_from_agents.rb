class RemoveWidgetGradientColorsFromAgents < ActiveRecord::Migration[7.1]
  def change
    remove_column :agents, :widget_gradient_colors, :text
  end
end
