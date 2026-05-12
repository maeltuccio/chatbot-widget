class WidgetAgentsController < ApplicationController
  before_action :set_cors_headers

  def show
    agent = Agent.find_by!(public_token: params[:public_token], active: true)
    return unless ensure_origin_allowed!(agent)

    render json: {
      name: agent.name,
      welcome_message: agent.welcome_message,
      tone: agent.tone,
      primary_goal: agent.primary_goal,
      widget_title: agent.widget_title,
      widget_primary_color: agent.widget_primary_color,
      widget_position: agent.widget_position,
      widget_send_label: agent.widget_send_label,
      widget_placeholder: agent.widget_placeholder
    }
  end

  private

  def ensure_origin_allowed!(agent)
    return true if agent.origin_allowed?(request.origin)

    head :forbidden
    false
  end

  def set_cors_headers
    response.headers["Access-Control-Allow-Origin"] = request.origin if request.origin.present?
    response.headers["Vary"] = "Origin"
  end
end
