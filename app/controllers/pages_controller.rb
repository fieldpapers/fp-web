require "raven"

class PagesController < ApplicationController
  # allow API usage
  skip_before_filter :verify_authenticity_token, only: :update

  def show
    @atlas = Atlas.friendly.find(params[:id])
    @page = @atlas.pages.find_by_page_number(params[:page_number])
  end

  def update
    atlas = Atlas.unscoped.friendly.find(params[:id])
    page = atlas.pages.find_by_page_number(params[:page_number])

    if ["render_page", "render_index"].include? params[:task]
      # this is a callback from our renderer
      page.update!(page_params.merge(composed_at: Time.now))
      page.atlas.rendered!
      page.atlas.save!
    elsif params[:error]
      logger.warn(params[:error][:message])
      logger.warn(params[:error][:stack])
      Raven.capture_message(params[:error][:message], extra: {
        stack: params[:error][:stack],
        atlas: atlas.slug,
        page: page.page_number,
      })
    else
      page.update!(page_params)
    end

    respond_to do |format|
      format.html {
        redirect_to atlas_page_atlas_url(page.atlas, page.page_number)
      }

      format.json {
        render status: 201, json: {}
      }
    end
  end

  private

  def page_params
    params.require(:page).permit(:pdf_url, :geotiff_url)
  end
end
