class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    @atlas_count = Atlas.unscoped.where(user_id: current_user.id).count
    @snapshot_count = Snapshot.unscoped.where(user_id: current_user.id).count
  end

  def destroy
    user = current_user
    user.delete_account!
    log_auth("delete", user_id: user.id)
    sign_out user
    redirect_to root_path, notice: _("Your account has been deleted.")
  end
end
