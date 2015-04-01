class PagesController < ApplicationController
  def show

    # TODO: Better way?
    @atlas = Atlas.find_by_slug(params[:id])

    @page = Page.find_by_atlas_id_and_page_number(@atlas.id, params[:page])
  end
end
