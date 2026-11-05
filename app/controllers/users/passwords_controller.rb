class Users::PasswordsController < Devise::PasswordsController
  rate_limit to: 10, within: 10.minutes, only: :create,
    by: -> { "ip:#{request.remote_ip}" }, with: -> { rate_limited(new_user_password_path) }
  # also limits reset emails sent to any one address
  rate_limit to: 3, within: 1.hour, only: :create,
    by: -> { "email:#{params.dig(:user, :email).to_s.strip.downcase}" }, with: -> { rate_limited(new_user_password_path) }
end
