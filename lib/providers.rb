# Base maps available for Fieldpapers
#
class Providers
  # Use layers <key>
  def self.default
    'openstreetmap'
  end

  def self.options()
    self.layers.map do |k, v|
      [v[:label], v[:template]]
    end
  end

  # TODO: is there a better way?
  def self.derive(url)
    if url.include? 'openstreetmap.org'
      'openstreetmap'
    elsif url.include? 'toner-lite'
      'toner'
    elsif url.include? 'boner'
      'satellite-labels'
    elsif url.include? 'bing-lite'
      'satellite-only'
    elsif url.include? 'openstreetmap.fr/hot'
      'humanitarian'
    elsif url.include? 'stamen.i808gmk6'
      'mapbox-satellite'
    elsif url.include? 'opencyclemap.org'
      'opencyclemap'
    else
      url
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
        },
        minzoom: 0,
        maxzoom: 19,
      },
      'toner': {
        label: 'Black & White',
        template: 'http://{S}.tile.stamen.com/toner-lite/{Z}/{X}/{Y}.png',
        options: {
          attribution: ''
        },
        minzoom: 0,
        maxzoom: 20,
      },
      'satellite-labels': {
        label: 'Satellite + Labels',
        template: 'http://{S}.tile.stamen.com/boner/{Z}/{X}/{Y}.jpg',
        options: {
          attribution: ''
        },
        minzoom: 0,
        maxzoom: 19,
      },
      'satellite-only': {
        label: 'Satellite Only',
        template: 'http://{S}.tile.stamen.com/bing-lite/{Z}/{X}/{Y}.jpg',
        options: {
          attribution: ''
        },
        minzoom: 0,
        maxzoom: 19,
      },
      'humanitarian': {
        label: 'Humanitarian',
        template: 'http://{S}.tile.openstreetmap.fr/hot/{Z}/{X}/{Y}.png',
        options: {
          attribution: ''
        },
        minzoom: 0,
        maxzoom: 20,
      },
      'mapbox-satellite': {
        label: 'Mapbox Satellite',
        template: 'http://{S}.tiles.mapbox.com/v3/stamen.i808gmk6/{Z}/{X}/{Y}.png',
        options: {
          attribution: ''
        },
        minzoom: 0,
        maxzoom: 19,
      },
      'opencyclemap': {
        label: 'OpenCycleMap',
        template: 'http://{S}.tile.opencyclemap.org/cycle/{Z}/{X}/{Y}.png',
        options: {
          attribution: ''
        },
        minzoom: 0,
        maxzoom: 20,
      },
    }
  end
end
