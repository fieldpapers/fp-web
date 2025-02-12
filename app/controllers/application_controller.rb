class ApplicationController < ActionController::Base
  before_action :redirect_www

  before_action :set_locale

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # per https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-sign-in-using-their-username-or-email-address
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def set_locale
    cookies[:locale] = params[:locale] if params[:locale]

    http_accept_language.user_preferred_languages.unshift cookies[:locale] if cookies[:locale]

    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def redirect_www
    if request.host.starts_with?('www.')
      redirect_to "https://#{request.host.sub('www.', '')}#{request.fullpath}", status: 301
    end
  end
end
