class ApplicationController < ActionController::Base
  before_action :redirect_www
  before_action :redirect_localhost, if: -> { Rails.env.development? }

  before_action :set_locale

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # per https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-sign-in-using-their-username-or-email-address
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
  end

  # Handler for rate_limit's with: option. Logs the request, then redirects to
  # path with a "too many attempts" alert, or responds with a 429 if no path
  # is given.
  def rate_limited(path = nil)
    logger.warn("rate limited: #{controller_path}##{action_name} ip=#{request.remote_ip}")
    return head(:too_many_requests) unless path
    redirect_to path, alert: _("Too many attempts. Please wait a few minutes and try again.")
  end

  # Logs account events (logins are logged by the Warden hooks in
  # config/initializers/devise.rb)
  def log_auth(event, **fields)
    Rails.logger.info(["auth event=#{event}", *fields.map { |k, v| "#{k}=#{v}" }].join(" "))
  end

  # Locale comes from the cookie set by LocalesController, falling back to
  # Accept-Language. Legacy ?locale= links still work, but redirect to the
  # canonical URL so crawlers don't see a copy of every page per locale.
  def set_locale
    if (locale = request.query_parameters["locale"])
      cookies.permanent[:locale] = locale
      query = request.query_parameters.except("locale").to_query
      return redirect_to [request.path, query.presence].compact.join("?")
    end

    http_accept_language.user_preferred_languages.unshift cookies[:locale] if cookies[:locale]

    # Inside an action, ActionView's I18n proxy ignores `I18n.locale = nil`, so
    # without the fallback a request would keep whatever locale the previous
    # request on this thread used.
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales) || I18n.default_locale
  end

  def redirect_www
    if request.host.starts_with?('www.')
      redirect_to "https://#{request.host.sub('www.', '')}#{request.fullpath}", status: 301
    end
  end

  # Cookies are per-host, and OSM only allows plain-http OAuth redirects on
  # 127.0.0.1, so we redirect requests to localhost there.
  def redirect_localhost
    if request.host == 'localhost'
      redirect_to "#{request.protocol}127.0.0.1:#{request.port}#{request.fullpath}"
    end
  end
end
