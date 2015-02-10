class AtlasesController < ApplicationController
  def index
    @atlases = Atlas.limit(5).offset(0)
  end
end
