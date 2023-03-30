require "raven"

class PagesController < ApplicationController
  # allow API usage
  skip_before_action :verify_authenticity_token, only: :update

  def show
    @atlas = Atlas.unscoped.friendly.find(params[:id])
    @page = @atlas.pages.find_by_page_number(params[:page_number])
  end

  def update
    atlas = Atlas.unscoped.friendly.find(params[:id])
    page = atlas.pages.find_by_page_number(params[:page_number])

    if params[:task] && params[:error]
      logger.warn(params[:error][:message])
      logger.warn(params[:error][:stack])
      Raven.capture_message(params[:error][:message], extra: {
        stack: params[:error][:stack],
        atlas: atlas.slug,
        page: page.page_number,
      })

      page.atlas.fail!
      page.atlas.save!
    elsif ["render_page", "render_index"].include? params[:task]
      # this is a callback from our renderer
      page.update!(page_params.merge(composed_at: Time.now))
      page.atlas.rendered!
      page.atlas.save!
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
    # :atlas param was causing some issues and doesn't seem to be needed so just delete it
    params[:page].delete :atlas
    params.require(:page).permit(:page_number, :pdf_url, :geotiff_url)
  end
end
