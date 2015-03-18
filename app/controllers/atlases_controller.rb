require "providers"
require 'csv'

class AtlasesController < ApplicationController
  # filters

  has_scope :date,  only: :index
  has_scope :month, only: :index
  has_scope :place, only: :index
  has_scope :user,  only: :index

  def index
    @atlases = apply_scopes(Atlas).page(params[:page])
    @counts = apply_scopes(Atlas).count('id')
  end

  def show
    # redirects for legacy URLs
    if params[:redirect]
      return redirect_to atlas_page_url(id: $1, page: $2) if params[:id] =~ /(\w+)\/(.+)/

      return redirect_to atlas_url(params[:id])
    end

    @atlas = Atlas.friendly.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf {
        # convenience redirect if "pdf" was provided as an extension
        return redirect_to @atlas.pdf_url if @atlas.pdf_url
        render status: 404
      }

      format.csv do
        filename = "activity-" + @atlas.slug + ".csv"
        headers['Content-Disposition'] = "attachment; filename=\""+filename+"\""
        headers['Content-Type'] ||= 'text/csv'
      end

    end
  end
end
