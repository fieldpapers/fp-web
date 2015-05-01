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

  def id_link(slug, zoom, lon, lat)
    "http://www.openstreetmap.org/edit#background=custom:#{FieldPapers::TILE_BASE_URL}/snapshots/#{slug}/{z}/{x}/{y}.png&map=#{zoom}/#{lat}/#{lon}"
  end

  def potlatch_link(slug, zoom, lon, lat)
    "http://www.openstreetmap.org/edit?lat=#{lat}&lon=#{lon}&zoom=#{zoom}&tileurl=#{FieldPapers::TILE_BASE_URL}/snapshots/#{slug}/$z/$x/$y.png"
  end
end
