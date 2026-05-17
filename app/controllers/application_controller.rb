class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :current_account

  private

  def current_account
    current_user&.account
  end

  def require_manager!
    return if current_user&.can_manage?

    redirect_to agents_path, alert: "Vous n'êtes pas autorisé à administrer cet espace de travail."
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:account_name])
  end
end
