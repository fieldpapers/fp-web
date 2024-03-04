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
      "#{FieldPapers::OSM_BASE_URL}/edit#background=custom:#{FieldPapers::TILE_BASE_URL}/snapshots/#{slug}/{z}/{x}/{y}.png&map=#{zoom}/#{lat}/#{lon}"
    else
      "#{FieldPapers::OSM_BASE_URL}/edit#map=#{zoom}/#{lat}/#{lon}"
    end
  end

  def potlatch_link(zoom, lon, lat, slug = nil)
    if slug
      "#{FieldPapers::OSM_BASE_URL}/edit?lat=#{lat}&lon=#{lon}&zoom=#{zoom}&tileurl=#{FieldPapers::TILE_BASE_URL}/snapshots/#{slug}/$z/$x/$y.png"
    else
      "#{FieldPapers::OSM_BASE_URL}/edit?lat=#{lat}&lon=#{lon}&zoom=#{zoom}"
    end
  end

  # derives URLs for HTTP GET requests needed for JOSM to load data and tiles.
  # Actual XHRs exist in <script> in show.html.erb.
  def josm_link(zoom, lon, lat, north, south, east, west, provider, slug = nil)
    josmremote = "http://127.0.0.1:8111"

    provider = provider.gsub("{S}", "{switch:a,b,c}").gsub("{Z}", "{zoom}").gsub("{Y}", "{y}").gsub("{X}", "{x}");

    # load data and zoom to extents
    dataRequest = "#{josmremote}/load_and_zoom?left=#{west}&right=#{east}&top=#{north}5&bottom=#{south}"

    # load tiles
    if slug
      tileRequest = "#{josmremote}/imagery?title=osm&type=tms&url=#{FieldPapers::TILE_BASE_URL}/snapshots/#{slug}/{zoom}/{x}/{y}.png"
    else
      tileRequest = "#{josmremote}/imagery?title=osm&type=tms&url=#{provider}"
    end

    return "data-data-request=#{dataRequest} data-tile-request=#{tileRequest}"
  end
end
