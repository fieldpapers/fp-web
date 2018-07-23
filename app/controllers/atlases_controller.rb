require "csv"
require "providers"
require "raven"

class AtlasesController < ApplicationController
  # filters

  has_scope :date,      only: :index
  has_scope :month,     only: :index
  has_scope :place,     only: :index
  has_scope :user,      only: :index
  has_scope :username,  only: :index

  # allow API usage
  skip_before_filter :verify_authenticity_token, only: :update

  def index
    @atlases = apply_scopes(Atlas.unscoped).default.by_creator(current_user).page(params[:page])
    @counts = apply_scopes(Atlas.unscoped).default.by_creator(current_user).count('id')
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

  def update
    atlas = Atlas.unscoped.find_by_slug(params[:id])

    if params[:task] && params[:error]
      logger.warn(params[:error][:message])
      logger.warn(params[:error][:stack])
      Raven.capture_message(params[:error][:message], extra: {
        stack: params[:error][:stack],
        atlas: atlas.slug,
      })

      atlas.fail!
      atlas.save!
    elsif params[:task] == "merge_pages"
      # this is a callback from our renderer
      atlas.update!(atlas_params)
      atlas.merged!
      atlas.save!
    else
      atlas.update!(atlas_params)
    end

    respond_to do |format|
      format.html {
        redirect_to atlas_url(atlas)
      }

      format.json {
        render status: 201, json: true
      }
    end
  end

  private

  def atlas_params
    params.require(:atlas).permit(:pdf_url)
  end
end
