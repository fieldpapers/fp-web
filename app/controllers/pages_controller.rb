class PagesController < ApplicationController
  def show
    @page = Page.find_by_atlas_id_and_page_number(params[:id], params[:page])
  end
end
