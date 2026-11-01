class HomeController < ApplicationController
  # The landing page, or for logged-in users, a dashboard of their own atlases
  # and snapshots (including private and failed ones).
  def index
    return unless user_signed_in?

    @atlases = Atlas.unscoped.where(user_id: current_user.id)
      .includes(:creator).order(created_at: :desc).load
    @page_counts = Page.where(atlas_id: @atlases.map(&:id)).group(:atlas_id).count

    @snapshots = Atlas.unscoped do
      Snapshot.unscoped.where(user_id: current_user.id)
        .includes(:uploader, :page, :atlas).order(created_at: :desc).load
    end

    render :dashboard
  end
end
