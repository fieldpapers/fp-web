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

  def iDLink(slug, zoom, lon, lat)
    "http://www.openstreetmap.us/iD/release/#background=custom:http://fieldpapers.org/files/scans/" + slug.to_s + "/{z}/{x}/{y}.jpg&map=" + zoom.to_s + "/" + lon.to_s + "/" + lat.to_s
  end

  def potlatchLink(slug, zoom, lon, lat)
    "http://www.openstreetmap.org/edit?lat=" + lat.to_s + "&lon=" + lon.to_s + "&zoom=" + zoom.to_s + "&tileurl=http://fieldpapers.org/files/scans/" + slug.to_s + "/$z/$x/$y.jpg"
  end
end
