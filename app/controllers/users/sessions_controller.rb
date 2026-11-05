class Users::SessionsController < Devise::SessionsController
  rate_limit to: 20, within: 10.minutes, only: :create,
    by: -> { "ip:#{request.remote_ip}" }, with: -> { rate_limited(new_user_session_path) }
  rate_limit to: 10, within: 1.hour, only: :create,
    by: -> { "login:#{params.dig(:user, :login).to_s.strip.downcase}" }, with: -> { rate_limited(new_user_session_path) }

  private

  # The header shows whether you're logged in, so these notices are redundant.
  def set_flash_message!(key, kind, options = {})
    super unless [:signed_in, :signed_out, :already_signed_out].include?(kind)
  end
end
