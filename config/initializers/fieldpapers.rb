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
  ATLAS_INDEX_HEADER_TILELAYER = ENV['ATLAS_INDEX_HEADER_TILELAYER'] || "https://{S}.tile.openstreetmap.org/{Z}/{X}/{Y}.png"

  if ENV["DEFAULT_CENTER"].present?
    DEFAULT_CENTER = ENV["DEFAULT_CENTER"]
    zoom, DEFAULT_LATITUDE, DEFAULT_LONGITUDE = ENV["DEFAULT_CENTER"].split("/").map(&:to_f)
    DEFAULT_ZOOM = zoom.to_i
  else
    DEFAULT_CENTER = nil
  end
end
