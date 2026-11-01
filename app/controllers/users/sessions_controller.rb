class Users::SessionsController < Devise::SessionsController
  private

  # The header shows whether you're logged in, so these notices are redundant.
  def set_flash_message!(key, kind, options = {})
    super unless [:signed_in, :signed_out, :already_signed_out].include?(kind)
  end
end
