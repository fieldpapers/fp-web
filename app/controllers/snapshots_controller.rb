class SnapshotsController < ApplicationController
  has_scope :date, only: :index
  has_scope :month, only: :index
  has_scope :place, only: :index
  has_scope :user, only: :index

  # @http_method XHR POST
  # @url /snapshots
  def create
    @snapshot = Snapshot.create(snapshot_params)
  end

  def index
    @snapshots = apply_scopes(Snapshot).page(params[:page])
    @counts = apply_scopes(Snapshot).count('id')
  end

  def show
    return redirect_to snapshot_url(params[:id]) if params[:redirect]

    @snapshot = Snapshot.unscoped.friendly.find(params[:id])
  end

  private

  def snapshot_params
    params.require(:snapshot)
      .permit(:s3_scene_url)
      .merge(scene_file_name: params.permit(:filepath)[:filepath],
             scene_content_type: params.permit(:filetype)[:filetype],
             scene_file_size: params.permit(:filesize)[:filesize])
      .merge(uploader: current_user)
  end
end
