require "placefinder"

class ComposeController < ApplicationController
  include Wicked::Wizard

  steps :search, :select, :describe, :layout

  def show
    # create an atlas instance with whatever we know about it at this point
    # (which could very well be nothing)
    @atlas = Atlas.new(session[:atlas] || {})

    case step
    when :search
      # we're starting our way through the wizard; clear out anything we know
      session[:atlas] = nil
    when :select
      if params[:q]
        # #select does double-duty and redirects to the center
        zoom, longitude, latitude = Placefinder.query(params[:q])

        return redirect_to wizard_path(:select, zoom: zoom, lat: latitude, lon: longitude)
      end
    end

    render_wizard
  end

  def update
    # initialize session storage of atlas attributes
    session[:atlas] ||= {
      creator: current_user
    }

    @atlas = Atlas.new \
      session[:atlas]
        .merge(atlas_params)

    # for stepwise validation see:
    #   https://github.com/schneems/wicked/wiki/Building-Partial-Objects-Step-by-Step
    # step attr (not persisted) makes sense
    if @atlas.valid?
      case step
      when :layout # final step
        @atlas.save

        # now that this atlas exists, clear out the session representation
        session[:atlas] = nil

        return redirect_to atlas_path(@atlas)
      else
        # update the session store
        session[:atlas] = @atlas.attributes

        # move on to the next step
        return redirect_to next_wizard_path
      end
    end

    render step
  end

  private

  def atlas_params
    params.require(:atlas).permit \
      :north, :south, :east, :west, :zoom, :rows, :cols, :orientation, :provider, # from select
      :title, :text, :private, # from describe
      :layout, :utm_grid, :redcross_overlay # from layout
  end

  def finish_wizard_path
    atlas_path(@atlas)
  end
end
