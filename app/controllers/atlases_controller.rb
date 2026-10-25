require "csv"
require "providers"

class AtlasesController < ApplicationController
  # filters

  has_scope :date,      only: :index
  has_scope :month,     only: :index
  has_scope :place,     only: :index
  has_scope :user,      only: :index
  has_scope :username,  only: :index

  def index
    @atlases = apply_scopes(Atlas.unscoped).default.by_creator(current_user).page(params[:page]).load
    @counts = @atlases.total_count
    @page_counts = Page.where(atlas_id: @atlases.map(&:id)).group(:atlas_id).count
  end

  def show
    @atlas = Atlas.unscoped.friendly.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf {
        # convenience redirect if "pdf" was provided as an extension
        return redirect_to @atlas.pdf_url if @atlas.pdf_url
        raise ActionController::RoutingError.new("Not Found")
      }

      format.csv do
        headers["Content-Type"] ||= "text/csv"
      end

      format.geojson do
        headers["Content-Type"] ||= "application/geo+json; charset=UTF-8"
      end
    end
  end
end
