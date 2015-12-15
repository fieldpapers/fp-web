require 'api-pagination'

module Api
  module V1
    class AtlasesController < ApplicationController
      include AtlasesHelper
      include SnapshotsHelper

      respond_to :json
      before_filter :find_atlas, only: [:show, :update, :destroy, :status, :page]

      skip_before_filter :verify_authenticity_token

      has_scope :date,  only: :index
      has_scope :month, only: :index
      has_scope :place, only: :index
      has_scope :user,  only: :index

      def index
        paginate json: apply_scopes(Atlas.unscoped).default { |a| atlas_to_geojson(a) }
      end

      def show
        respond_to do |format|
          format.json { render_atlas }
          format.pdf  { redirect_to @atlas.pdf_url, status: :see_other }
        end
      end

      def create
        @atlas = Atlas.create atlas_params
        if @atlas.valid?
          @atlas.save
          @atlas.render!
          render_atlas
        else
          render status: :bad_request,
                 json: { message: "Failed to create new atlas" }
        end
      end

      def update
        @atlas.update(atlas_params)
        render_atlas
      end

      def destroy
        @atlas.destroy
        render_atlas
      end

      def status
        render json: { progress: @atlas.progress,
                       workflow_state: @atlas.workflow_state,
                       composed_at: @atlas.composed_at,
                       created_at: @atlas.created_at,
                       failed_at: @atlas.failed_at,
                       updated_at: @atlas.updated_at }
      end

      def page
        begin
          page = @atlas.pages.find_by_page_number(params[:page_number])
          respond_to do |format|
            format.json { render json: page_to_geojson(@atlas, page) }
            format.pdf  { redirect_to page.pdf_url, status: :see_other }
          end
        rescue ActiveRecord::RecordNotFound
          render status: :not_found,
                 json: { message: "Page '#{params[:page_number]} not " \
                                  "found in atlas '#{params[:id]}'" }
        end
      end

      private

      def find_atlas
        begin
          @atlas = Atlas.unscoped.friendly.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render status: :not_found,
                 json: { message: "Atlas ID '#{params[:id]}' not found" }
        end
      end

      def render_atlas
        render json: atlas_to_geojson(@atlas)
      end

      def atlas_params
        params.require(:atlas).permit \
          :north, :south, :east, :west, :zoom, :rows, :cols,
          :paper_size, :orientation, :layout, :provider,
          :title, :text, :private, :utm_grid, :redcross_overlay
      end
    end
  end
end
