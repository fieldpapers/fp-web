# OpenStreetMap OAuth login. After the OAuth flow verifies the user, we match
# their OSM ID against the osm_id column in the Field Papers users table, and
# create a new row if no match is found.
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def osm
    auth = request.env["omniauth.auth"]
    osm_id = Integer(auth.uid)
    name = auth.info.nickname
    user = User.find_by(osm_id: osm_id)
    legacy = current_user if current_user && current_user.osm_id.nil?

    if user && legacy
      # two user entries exist (one for the OSM identity and another for the
      # legacy user) so merge them together
      user.absorb!(legacy)
      user.update!(username: name)
      log_auth("merge", from_user_id: legacy.id, user_id: user.id)
      sign_in user
      redirect_to account_path, notice: _("Your old account %{username} has been merged into this one.") % { username: legacy.username }
    elsif user
      user.update!(username: name)
      sign_in_and_redirect user
    elsif legacy
      # the user was already logged in with username and password before the
      # OSM OAuth flow; link their account to their OSM identity
      legacy.update!(osm_id: osm_id, username: name)
      log_auth("link", user_id: legacy.id, osm_id: osm_id)
      redirect_to account_path, notice: _("Your Field Papers account is now connected to OpenStreetMap.")
    elsif current_user
      redirect_to account_path, alert: _("Your Field Papers account is already connected to a different OpenStreetMap account.")
    else
      user = User.create!(osm_id: osm_id, username: name)
      log_auth("signup", user_id: user.id, osm_id: osm_id)
      sign_in user
      redirect_to account_path, notice: _("Welcome to Field Papers! If you had a Field Papers account before logging in with OpenStreetMap, you can merge it into this one below.")
    end
  end

  def failure
    log_auth("login", outcome: "failure", method: "osm", reason: failure_message)
    redirect_to new_user_session_path, alert: _("Logging in with OpenStreetMap failed (%{reason}).") % { reason: failure_message }
  end
end
