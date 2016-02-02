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

  def josm_link(north, south, east, west, slug = nil)
    protocol = URI.parse(request.original_url).scheme
    port = protocol == "https" ? "8112" : "8111"
    domain = "127.0.0.1"

    # The OSM server refuses requests above a certain size bounding box (~0.5deg x 0.5deg)
    # http://wiki.openstreetmap.org/wiki/Downloading_data
    # 
    # zoomVal = 0.25
    # zoomedwest = west + zoomVal * (east - west)
    # zoomedeast = east + zoomVal * (west - east)
    # zoomednorth = north + zoomVal * (south - north)
    # zoomedsouth = south + zoomVal * (north - south)
    # west = zoomedwest
    # east = zoomedeast
    # north = zoomednorth
    # south = zoomedsouth

    if slug
      "#{protocol}://#{domain}:#{port}/load_and_zoom?left=#{west}&right=#{east}&top=#{north}5&bottom=#{south}"
      # "#{protocol}://#{domain}:#{port}/load_and_zoom?left=#{west}&right=#{east}&top=#{north}5&bottom=#{south}&slug=#{slug}"
    else
      "#{protocol}://#{domain}:#{port}/load_and_zoom?left=#{west}&right=#{east}&top=#{north}5&bottom=#{south}"
    end
  end
end
