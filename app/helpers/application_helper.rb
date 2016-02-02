module ApplicationHelper

  # Used to set the active navbar item
  def current_nav_target
    target = ""
    if controller_name == "compose"
      target = "compose"
    elsif controller_name == 'snapshots' && action_name == 'new'
      target = 'upload'
    elsif ["snapshots", "atlases"].include? controller_name
      target = 'watch'
    elsif controller_name == 'home' && action_name == 'advanced'
      target = 'extend'
    elsif ["sessions","registrations","confirmations"].include? controller_name
      target = 'sessions'
    end
    return target
  end

  def id_link(zoom, lon, lat, slug = nil)
    if slug
      "http://www.openstreetmap.org/edit#background=custom:#{FieldPapers::TILE_BASE_URL}/snapshots/#{slug}/{z}/{x}/{y}.png&map=#{zoom}/#{lat}/#{lon}"
    else
      "http://www.openstreetmap.org/edit#map=#{zoom}/#{lat}/#{lon}"
    end
  end

  def potlatch_link(zoom, lon, lat, slug = nil)
    if slug
      "http://www.openstreetmap.org/edit?lat=#{lat}&lon=#{lon}&zoom=#{zoom}&tileurl=#{FieldPapers::TILE_BASE_URL}/snapshots/#{slug}/$z/$x/$y.png"
    else
      "http://www.openstreetmap.org/edit?lat=#{lat}&lon=#{lon}&zoom=#{zoom}"
    end
  end

  # derives URLs for HTTP GET requests needed for JOSM to load data and tiles.
  # Actual XHRs exist in <script> in show.html.erb.
  def josm_link(zoom, lon, lat, north, south, east, west, slug = nil)
    protocol = URI.parse(request.original_url).scheme
    port = protocol == "https" ? "8112" : "8111"
    domain = "127.0.0.1"

    # The OSM server refuses requests above a certain size bounding box (~0.5deg x 0.5deg)
    # http://wiki.openstreetmap.org/wiki/Downloading_data
    # This code shrinks the bounding box for testing.
    zoomVal = 0.4
    zoomedwest = west + zoomVal * (east - west)
    zoomedeast = east + zoomVal * (west - east)
    zoomednorth = north + zoomVal * (south - north)
    zoomedsouth = south + zoomVal * (north - south)
    west = zoomedwest
    east = zoomedeast
    north = zoomednorth
    south = zoomedsouth

    # load OSM data and zoom to extents
    dataRequest = "#{protocol}://#{domain}:#{port}/load_and_zoom?left=#{west}&right=#{east}&top=#{north}5&bottom=#{south}"
    # TODO: do slugs mean anything to JOSM or can we just omit them?
    # "#{protocol}://#{domain}:#{port}/load_and_zoom?left=#{west}&right=#{east}&top=#{north}5&bottom=#{south}&slug=#{slug}"

    # load OSM tiles
    tileRequest = "#{protocol}://#{domain}:#{port}/imagery?title=osm&type=tms&url=https://a.tile.openstreetmap.org/#{zoom}/#{lon}/#{lat}.png"

    return "data-data-request=#{dataRequest} data-tile-request=#{tileRequest}"
  end
end
