require 'api-pagination'

module Api
  module V1
    class SnapshotsController < ApplicationController
      include AtlasesHelper
      include SnapshotsHelper

      respond_to :json
      before_filter :find_snapshot, only: [:show, :destroy, :status, :page]

      skip_before_filter :verify_authenticity_token

      has_scope :date, only: :index
      has_scope :month, only: :index
      has_scope :place, only: :index
      has_scope :user, only: :index

      def index
        paginate({ json: apply_scopes(Snapshot.unscoped).default do |s|
                     snapshot_to_geojson(s.atlas_id ?
                                           Atlas.find(s.atlas_id) : nil, s)
                   end })
      end

      def show
        respond_to do |format|
          format.png  { redirect_to @snapshot.s3_scene_url, status: :see_other }
          format.json { render_snapshot }
          format.tiff { redirect_to @snapshot.geotiff_url, status: :see_other }
        end
      end

      def create
        begin
          @snapshot = Snapshot.create!(snapshot_upload_params)
          @snapshot.process!
          render_snapshot
        rescue
          render status: :bad_request,
                 json: { message: "Failed to create new snapshot" }
        end
      end

      def destroy
        @snapshot.destroy
        render_snapshot
      end

      def status
        render json: { progress: @snapshot.progress,
                       has_geotiff: @snapshot.has_geotiff,
                       has_geojpeg: @snapshot.has_geojpeg,
                       decoded_at: @snapshot.decoded_at,
                       created_at: @snapshot.created_at,
                       failed_at: @snapshot.failed_at,
                       updated_at: @snapshot.updated_at }
      end

      private

      def find_snapshot
        begin
          @snapshot = Snapshot.unscoped.friendly.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render status: :not_found,
                 json: { message: "Snapshot ID '#{params[:id]}' not found" }
        end
      end

      def render_snapshot
        atlas = @snapshot.atlas_id ? Atlas.find(@snapshot.atlas_id) : nil
        render json: snapshot_to_geojson(atlas, @snapshot)
      end


      def snapshot_upload_params
        params.permit(:s3_scene_url)
      end
    end
  end
end
