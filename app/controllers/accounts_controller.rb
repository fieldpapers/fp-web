class AccountsController < ApplicationController
  before_action :authenticate_user!
  # merging checks a legacy account's password, so this is limited like logins
  rate_limit to: 10, within: 1.hour, only: :merge,
    by: -> { "user:#{current_user.id}" }, with: -> { rate_limited(account_path) }
  rate_limit to: 10, within: 1.hour, only: :merge,
    by: -> { "login:#{params[:login].to_s.strip.downcase}" }, with: -> { rate_limited(account_path) }

  def show
    @atlas_count = Atlas.unscoped.where(user_id: current_user.id).count
    @snapshot_count = Snapshot.unscoped.where(user_id: current_user.id).count
  end

  # Moves a legacy account's content into this (OSM) account, given the
  # legacy account's username (or email) and password.
  def merge
    login, password = params[:login].to_s, params[:password].to_s
    legacy = User.find_for_database_authentication(login: login) if login.present?
    if current_user.osm_id && password.present? && legacy&.legacy_password_valid?(password)
      current_user.absorb!(legacy)
      log_auth("merge", from_user_id: legacy.id, user_id: current_user.id)
      redirect_to account_path, notice: _("Your old account %{username} has been merged into this one.") % { username: legacy.username }
    else
      log_auth("merge", outcome: "failure", user_id: current_user.id)
      redirect_to account_path, alert: _("Wrong username or password.")
    end
  end

  def destroy
    user = current_user
    user.delete_account!
    log_auth("delete", user_id: user.id)
    sign_out user
    redirect_to root_path, notice: _("Your account has been deleted.")
  end
end
