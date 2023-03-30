require "raven"

class SnapshotsController < ApplicationController
  has_scope :date, only: :index
  has_scope :month, only: :index
  has_scope :place, only: :index
  has_scope :user, only: :index
  has_scope :username, only: :index

  # allow API usage
  skip_before_action :verify_authenticity_token, only: [:create, :update]

  def new
    @snapshot = Snapshot.new
  end

  # @http_method XHR POST
  # @url /snapshots
  def create
    @snapshot = Snapshot.create!(snapshot_upload_params)
    @snapshot.process!

    redirect_to snapshot_url(@snapshot) unless request.xhr?
  end

  def index
    @snapshots = apply_scopes(Snapshot.unscoped).default.by_creator(current_user).page(params[:page])
    @counts = apply_scopes(Snapshot.unscoped).default.by_creator(current_user).count('id')

    respond_to do |format|
      format.html

      # the grid CSV only makes sense if this is scoped beneath an atlas
      if params[:atlas_id]
        @atlas = Atlas.unscoped.friendly.find(params[:atlas_id])
        format.csv do
          headers["Content-Type"] ||= "text/csv"
        end
      end
    end
  end

  def show
    @snapshot = Snapshot.unscoped.friendly.find(params[:id])
  end

  def update
    snapshot = Snapshot.unscoped.friendly.find(params[:id])

    if params[:task] && params[:error]
      logger.warn(params[:error][:message])
      logger.warn(params[:error][:stack])
      Raven.capture_message(params[:error][:message], extra: {
        stack: params[:error][:stack],
        snapshot: snapshot.slug,
      })

      snapshot.fail!
      snapshot.save!
    elsif params[:task] == "process_snapshot"
      # this is a callback from our renderer
      snapshot.update!(snapshot_update_params)
      snapshot.processed!
      snapshot.save!
    elsif params[:task] == "fetch_snapshot_metadata"
      # this is a callback from our renderer
      snapshot.update!(snapshot_update_params)
      snapshot.metadata_fetched!
      snapshot.save!
    else
      snapshot.update!(snapshot_update_params)
    end

    respond_to do |format|
      format.html {
        redirect_to snapshot_url(snapshot)
      }

      format.json {
        render status: 201, json: true
      }
    end
  end

  private

  def snapshot_upload_params
    case FieldPapers::PERSIST
    when "local"
      params.require(:snapshot)
        .permit(:scene)
        .merge(uploader: current_user)
    when "s3"
      params.require(:snapshot)
        .permit(:s3_scene_url)
        .merge(scene_file_name: params.permit(:filepath)[:filepath],
               scene_content_type: params.permit(:filetype)[:filetype],
               scene_file_size: params.permit(:filesize)[:filesize])
        .merge(uploader: current_user)
    end
  end

  def snapshot_update_params
    params.require(:snapshot)
      .permit(:geotiff_url, :page_url, :private, :zoom, bbox: [])
  end
end
