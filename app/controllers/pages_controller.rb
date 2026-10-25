class PagesController < ApplicationController
  def show
    @atlas = Atlas.unscoped.friendly.find(params[:id])
    @page = @atlas.pages.find_by_page_number(params[:page_number])
  end
end
