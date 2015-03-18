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

  # Requires record with: [slug,zoom,longitude,latitude]
  def iDLink(obj)
    "http://www.openstreetmap.us/iD/release/#background=custom:http://fieldpapers.org/files/scans/" + obj.slug + "/{z}/{x}/{y}.jpg&map=" + obj.zoom.to_s + "/" + obj.longitude.to_s + "/" +obj.latitude.to_s
  end

  # Requires record with: [slug,zoom,longitude,latitude]
  def potlatchLink(obj)
    "http://www.openstreetmap.org/edit?lat=" + obj.latitude.to_s + "&lon=" + obj.longitude.to_s + "&zoom=" + obj.zoom.to_s + "&tileurl=http://fieldpapers.org/files/scans/" + obj.slug + "/$z/$x/$y.jpg"
  end
end
