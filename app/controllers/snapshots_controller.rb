class SnapshotsController < ApplicationController
  has_scope :date, only: :index
  has_scope :month, only: :index
  has_scope :place, only: :index
  has_scope :user, only: :index

  def index
    @snapshots = apply_scopes(Snapshot).page(params[:page])
  end

  def show
    return redirect_to snapshot_url(params[:id]) if params[:redirect]

    @snapshot = Snapshot.find(params[:id])
  end
end
