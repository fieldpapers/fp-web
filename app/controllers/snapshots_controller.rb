class SnapshotsController < ApplicationController
  def index
    @snapshots = Snapshot.page(params[:page])
  end

  def show
    return redirect_to snapshot_url(params[:id]) if params[:redirect]

    @snapshot = Snapshot.find(params[:id])
  end
end
