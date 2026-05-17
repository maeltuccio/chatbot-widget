class WidgetTestsController < ApplicationController
  skip_before_action :authenticate_user!, if: -> { Rails.env.development? }
  def show
    @agent = if params[:agent_token].present?
      Agent.find_by(public_token: params[:agent_token])
    else
      Agent.first
    end
  end
end
