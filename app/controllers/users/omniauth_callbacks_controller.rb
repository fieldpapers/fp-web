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

    if legacy
      # the user logged in with their password to a legacy account
      if user
        # ... and another account already exists for the OSM account they
        # just proved that they own, so find it and merge the two together
        user.absorb!(legacy)
        user.update!(username: name)
        log_auth("merge", from_user_id: legacy.id, user_id: user.id)
        notice = _("Your old account %{username} has been merged into this one.") % { username: legacy.username }
      else
        # ... and no account for the OSM user exists yet, so create one
        # and then merge this legacy user into it
        user = User.create!(osm_id: osm_id, username: name)
        user.absorb!(legacy)
        log_auth("link", from_user_id: legacy.id, user_id: user.id, osm_id: osm_id)
        notice = _("Your Field Papers account is now connected to OpenStreetMap.")
      end
      sign_in user
      redirect_to account_path, notice: notice
    elsif user
      user.update!(username: name)
      sign_in_and_redirect user
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
