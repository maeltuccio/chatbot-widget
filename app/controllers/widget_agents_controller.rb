class WidgetAgentsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_cors_headers

  def show
    response.headers["Cache-Control"] = "no-store"

    agent = Agent.find_by!(public_token: params[:public_token])
    head :not_found and return unless agent.active? || backoffice_preview_allowed?(agent)

    return unless ensure_origin_allowed!(agent)

    render json: {
      name: agent.name,
      welcome_message: agent.welcome_message,
      tone: agent.tone,
      primary_goal: agent.primary_goal,
      widget_title: agent.widget_title,
      widget_primary_color: agent.widget_primary_color,
      widget_position: agent.widget_position,
      widget_theme: agent.widget_theme,
      widget_show_title: agent.widget_show_title,
      widget_send_label: agent.widget_send_label,
      widget_placeholder: agent.widget_placeholder
    }
  end

  private

  def ensure_origin_allowed!(agent)
    return true if agent.origin_allowed?(request.origin) || backoffice_preview_allowed?(agent)

    head :forbidden
    false
  end

  def backoffice_preview_allowed?(agent)
    same_backoffice_origin? && current_user&.account_id == agent.account_id
  end

  def same_backoffice_origin?
    request.origin == request.base_url ||
      request.referer.to_s.start_with?("#{request.base_url}/")
  end

  def set_cors_headers
    response.headers["Access-Control-Allow-Origin"] = request.origin if request.origin.present?
    response.headers["Vary"] = "Origin"
  end
end
