class PagesController < ApplicationController
  def show
    @atlas = Atlas.unscoped.find_by!(slug: params[:id])
    @page = @atlas.pages.find_by_page_number(params[:page_number])
  end
end
