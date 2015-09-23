require 'socket'

module FieldPapers
  # On AWS, it's hard to set up bidirectional links between named
  # Docker containers, so use numerical IP addresses for callback URLs
  # instead.
  if Rails.env.production?
    addr = Socket.ip_address_list.detect{ |i| i.ipv4? and !i.ipv4_loopback? }
    base_url_tmp = "http://#{addr.ip_address}:3000"
  end
  BASE_URL = base_url_tmp || ENV["BASE_URL"] || "http://fieldpapers.org"
  TASK_BASE_URL = ENV["TASK_BASE_URL"] || "http://tasks.fieldpapers.org"
  TILE_BASE_URL = ENV["TILE_BASE_URL"] || "http://tiles.fieldpapers.org"
end
