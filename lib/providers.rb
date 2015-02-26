# Base maps available for Fieldpapers
#
class Providers < ActiveRecord::Base
  # Use layers <key>
  def self.default
    'openstreetmap'
  end

  def self.options()
    self.layers.map do |k, v|
      [v[:label], v[:template]]
    end
  end

  # For layer options see: http://leafletjs.com/reference.html#tilelayer
  # templates are (currently) expected to be ModestMaps-formatted, which means
  # capital letters for placeholders
  def self.layers
    {
      'openstreetmap': {
        label: 'OpenStreetMap',
        template: 'http://{S}.tile.openstreetmap.org/{Z}/{X}/{Y}.png',
        options: {
          attribution: ''
        }
      },
      'toner': {
        label: 'Black & White',
        template: 'http://{S}.tile.stamen.com/toner-lite/{Z}/{X}/{Y}.png',
        options: {
          attribution: ''
        }
      },
      'satellite-labels': {
        label: 'Satellite + Labels',
        template: 'http://{S}.tile.stamen.com/boner/{Z}/{X}/{Y}.jpg',
        options: {
          attribution: ''
        }
      },
      'satellite-only': {
        label: 'Satellite Only',
        template: 'http://{S}.tile.stamen.com/bing-lite/{Z}/{X}/{Y}.jpg',
        options: {
          attribution: ''
        }
      },
      'humanitarian': {
        label: 'Humanitarian',
        template: 'http://{S}.tile.openstreetmap.fr/hot/{Z}/{X}/{Y}.png',
        options: {
          attribution: ''
        }
      },
      'mapbox-satellite': {
        label: 'Mapbox Satellite',
        template: 'http://api.tiles.mapbox.com/v3/stamen.i808gmk6/{Z}/{X}/{Y}.png',
        options: {
          attribution: ''
        }
      },
      'opencyclemap': {
        label: 'OpenCycleMap',
        template: 'http://{S}.tile.opencyclemap.org/cycle/{Z}/{X}/{Y}.png',
        options: {
          attribution: ''
        }
      }
    }
  end
end
