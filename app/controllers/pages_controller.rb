class PagesController < ApplicationController
  def show

    @atlas = Atlas.find_by_slug(params[:id])
    @page = @atlas.pages.find_by_page_number(params[:page])

  end
end
