# Base maps available for Fieldpapers
#
class Providers < ActiveRecord::Base
  # Use layers <key>
  def self.default
    'openstreetmap'
  end

  def self.options()
    out = []
    self.layers.each do |k, v|
      out.push([v[:label], k.to_s()])
    end
    return out
  end

  # For layer options see: http://leafletjs.com/reference.html#tilelayer
  def self.layers
    {
      'openstreetmap': {
        label: 'OpenStreetMap',
        template: 'http://tile.openstreetmap.org/{z}/{x}/{y}.png',
        options: {
          subdomains: '',
          attribution: ''
        }
      },
      'toner': {
        label: 'Black & White',
        template: 'http://{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png',
        options: {
          subdomains: 'abcd',
          attribution: ''
        }
      },
      'satellite-labels': {
        label: 'Satellite + Labels',
        template: 'http://tile.stamen.com/boner/{Z}/{X}/{Y}.jpg',
        options: {
          subdomains: '',
          attribution: ''
        }
      },
      'satellite-only': {
        label: 'Satellite Only',
        template: 'http://tile.stamen.com/bing-lite/{Z}/{X}/{Y}.jpg',
        options: {
          subdomains: '',
          attribution: ''
        }
      },
      'humanitarian': {
        label: 'Humanitarian',
        template: 'http://a.tile.openstreetmap.fr/hot/{Z}/{X}/{Y}.png',
        options: {
          subdomains: '',
          attribution: ''
        }
      },
      'mapbox-satellite': {
        label: 'Mapbox Satellite',
        template: 'http://api.tiles.mapbox.com/v3/stamen.i808gmk6/{Z}/{X}/{Y}.png',
        options: {
          subdomains: '',
          attribution: ''
        }
      },
      'opencyclemap': {
        label: 'OpenCycleMap',
        template: 'http://tile.opencyclemap.org/cycle/{Z}/{X}/{Y}.png',
        options: {
          subdomains: '',
          attribution: ''
        }
      }
    }
  end
end