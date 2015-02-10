class AtlasesController < ApplicationController
  def index
    @atlases = Atlas.limit(5).offset(0)
  end

  def show
    @atlas = Atlas.find(params[:id])
  end
end
