require 'socket'

module FieldPapers
  BASE_URL = ENV["BASE_URL"] || "https://fieldpapers.org"
  STATIC_URI_PREFIX = ENV["STATIC_URI_PREFIX"] || BASE_URL
  STATIC_PATH = ENV["STATIC_PATH"] || "./public"
  TASK_BASE_URL = ENV["TASK_BASE_URL"] || "https://tasks.fieldpapers.org"
  TILE_BASE_URL = ENV["TILE_BASE_URL"] || "https://tiles.fieldpapers.org"
  PERSIST = ENV["PERSIST"] || "s3"
  OSM_BASE_URL = ENV["OSM_BASE_URL"] || "https://www.openstreetmap.org"
  ATLAS_COMPLETE_WEBHOOKS = ENV["ATLAS_COMPLETE_WEBHOOKS"] || ""
  ATLAS_INDEX_HEADER_TILELAYER = ENV['ATLAS_INDEX_HEADER_TILELAYER'] || "https://tile.openstreetmap.org/{Z}/{X}/{Y}.png"

  # Optional analytics snippet injected into the <head> of every page. Supply
  # either ANALYTICS_HEAD_FILE (path to an HTML file, read once at boot) or
  # ANALYTICS_HEAD_HTML (the HTML inline); the file takes precedence. The file
  # path defaults to /etc/fieldpapers/analytics.html. When no file is found
  # and no inline HTML is set, no analytics markup is emitted.
  ANALYTICS_HEAD_FILE = ENV["ANALYTICS_HEAD_FILE"].presence || "/etc/fieldpapers/analytics.html"
  ANALYTICS_HEAD =
    if File.readable?(ANALYTICS_HEAD_FILE)
      File.read(ANALYTICS_HEAD_FILE)
    else
      ENV["ANALYTICS_HEAD_HTML"]
    end.presence

  if ENV["DEFAULT_CENTER"].present?
    DEFAULT_CENTER = ENV["DEFAULT_CENTER"]
    zoom, DEFAULT_LATITUDE, DEFAULT_LONGITUDE = ENV["DEFAULT_CENTER"].split("/").map(&:to_f)
    DEFAULT_ZOOM = zoom.to_i
  else
    DEFAULT_CENTER = nil
  end
end
