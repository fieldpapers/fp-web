require "placefinder"
require "providers"
require "json"
require "geo"

class ComposeController < ApplicationController
  include Wicked::Wizard

  # allow existing forms (w/o CSRF projection) to create canned atlases
  skip_before_filter :verify_authenticity_token, only: :create

  steps :search, :select, :describe, :layout

  def show
    # create an atlas instance with whatever we know about it at this point
    # (which could very well be nothing)
    @atlas = Atlas.new(session[:atlas] || {})

    case step
    when :search
      # we're starting our way through the wizard; clear out anything we know
      session[:atlas] = nil unless params[:canned]
    when :select
      if params[:q]
        # #select does double-duty and redirects to the center
        zoom, longitude, latitude = Placefinder.query(params[:q])

        return redirect_to wizard_path(:select, zoom: zoom, lat: latitude, lon: longitude)
      end
    end

    render_wizard
  end

  def create
    # raw geojson data
    if params[:geojson_data]
      # params[:geojson_data] is a String,
      # so need to convert to JSON
      geojson = JSON.parse(params[:geojson_data])

      # TODO: need to validate geojson

      props = geojson['properties']


      # TODO: need to validate geojson props
      params[:atlas] = {
        title: props['title'] || '',
        text: props['description'] || '',
        paper_size: props['paper_size'] || 'letter',
        orientation: props['orientation'] || 'landscape',
        layout: props['layout'] || 'full-page',
        utm_grid: props['utm_grid'] || false,
        redcross_overlay: props['redcross_overlay'] || false,
        zoom: props['zoom'] || 16,
        provider: Providers.layers[Providers.default.to_sym][:template],
        west: nil,
        south: nil,
        east: nil,
        north: nil,
        rows: 0,
        cols: 0
      }

      templates = []

      for feature in geojson['features']
        b = nil
        p = feature['properties']

        templates.push(p['provider'] || Providers.layers[Providers.default.to_sym][:template])
        zoom = p['zoom'] || 16

        if feature['geometry']['type'] == 'Point'
          b = point_extent(feature['geometry']['coordinates'], zoom, [1200, 1200])
        elsif feature['geometry']['type'] == 'Polygon'
          b = polygon_extent(feature['geometry']['coordinates'])
        else
          # skip
        end

        if !b.nil?
          if params[:atlas][:west].nil?
            params[:atlas][:west] = b[0]
          else
            params[:atlas][:west] = [params[:atlas][:west], b[0]].min
          end

          if params[:atlas][:east].nil?
            params[:atlas][:east] = b[2]
          else
            params[:atlas][:east] = [params[:atlas][:east], b[2]].max
          end

          if params[:atlas][:north].nil?
            params[:atlas][:north] = b[3]
          else
            params[:atlas][:north] = [params[:atlas][:north], b[3]].max
          end

          if params[:atlas][:south].nil?
            params[:atlas][:south] = b[1]
          else
            params[:atlas][:south] = [params[:atlas][:south], b[1]].min
          end
        end
      end

      # TODO: figure out how to calculate rows & columns
      # TODO: how to handle providers & zooms for pages ("features")
      return redirect_to wizard_path(:search)
    end

    # geojson file
    if params[:geojson_file]
      return redirect_to wizard_path(:search)
    end

    # convert params into a form that ActiveRecord likes (retaining old input
    # names)
    params[:atlas] = {
      title: params[:atlas_title],
      text: params[:atlas_text],
      provider: params[:atlas_provider]
    }

    latitude, longitude, zoom = params[:atlas_location].split(/,\s*| /).map(&:strip)
    zoom ||= 12 # arbitrary zoom

    session[:atlas] = params[:atlas].merge({
      creator: current_user
    })

    return redirect_to wizard_path(:select, zoom: zoom, lat: latitude, lon: longitude) if latitude && longitude

    redirect_to wizard_path(:search, canned: true)
  end

  def update
    # initialize session storage of atlas attributes
    session[:atlas] ||= {
      creator: current_user
    }

    @atlas = Atlas.new \
      session[:atlas]
        .merge(atlas_params)

    # for stepwise validation (not implemented due to reasonable defaults) see:
    #   https://github.com/schneems/wicked/wiki/Building-Partial-Objects-Step-by-Step
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
      :layout, :utm_grid, :redcross_overlay, :paper_size, # from layout
      :refreshed_from, :cloned_from
  end

  def finish_wizard_path
    atlas_path(@atlas)
  end

  def point_extent(point, zoom, dimensions)
    px = Geo::Utils.pixel_coord(point[0], point[1], zoom)
    top_left_px = [
      px[0] - (dimensions[0] / 2),
      px[1] - (dimensions[1] / 2)
    ]
    bottom_right_px = [
      px[0] + (dimensions[0] / 2),
      px[1] + (dimensions[1] / 2)
    ]

    west_north = Geo::Utils.ll_coord(top_left_px[0], top_left_px[1], zoom)
    east_south = Geo::Utils.ll_coord(bottom_right_px[0], bottom_right_px[1], zoom)

    return [
      west_north[0],
      east_south[1],
      east_south[0],
      west_north[1]
    ]

  end

  def polygon_extent(coords)
    coords = coords[0]

    longitude_minmax = coords.minmax_by { |c| c[0]}
    latitude_minmax = coords.minmax_by { |c| c[1]}

    west = longitude_minmax[0][0]
    south = latitude_minmax[0][1]
    east = longitude_minmax[1][0]
    north = latitude_minmax[1][1]

    return [west, south, east, north]

  end
end
