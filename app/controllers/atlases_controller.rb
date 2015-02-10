class AtlasesController < ApplicationController
  def index
    @atlases = Atlas.limit(5).offset(0)
  end

  def show
    if params[:redirect] and params[:id] =~ /(\w+)\/(.+)/
      return redirect_to atlas_page_url(id: $1, page: $2)
    elsif params[:redirect]
      return redirect_to atlas_url(params[:id])
    end

    @atlas = Atlas.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf { redirect_to @atlas.pdf_url }
    end
  end

  def show_page
    @page = Page.find_by_print_id_and_page_number(params[:id], params[:page])
  end
end
