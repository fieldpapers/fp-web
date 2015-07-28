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
    elsif url.include? 'kll.ptthjjor'
      'humanitarian-nepal'
    elsif url.include? 'stamen.i808gmk6'
      'mapbox-satellite'
    elsif url.include? 'opencyclemap.org'
      'opencyclemap'
    elsif url.include? 'sputnik.ru'
      'sputnik.ru'
    else
      url
    end
  end

  def self.get_layer_from_url(url)
    layer_key = self.derive(url)
    obj = self.layers.select do |k,v|
      k.to_s == layer_key
    end.values
  end

  def self.get_template_from_url(url)
    provider_layer = self.get_layer_from_url(url)
    if provider_layer && !provider_layer[0].nil?
      return provider_layer[0][:template]
    end
    url
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
      'humanitarian-nepal': {
        label: 'Humanitarian-Nepal',
        template: 'https://{S}.tiles.mapbox.com/v4/kll.ptthjjor/{Z}/{X}/{Y}@2x.png?access_token=pk.eyJ1Ijoia2xsIiwiYSI6IktVRUtfQnMifQ.GJAHJPvusgK_f0NsSXS8QA',
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
      'sputnik.ru': {
        label: 'Sputnik.RU',
        template: 'http://{S}.tiles.maps.sputnik.ru/{z}/{x}/{y}.png',
        options: {
          attribution: ' © <a href="http://sputnik.ru">Спутник</a> | © <a href="http://www.openstreetmap.org/copyright">Openstreetmap</a> | © <a href="http://www.naturalearthdata.com/about/terms-of-use/">Natural Earth</a> '
        },
        minzoom: 0,
        maxzoom: 19,
      },

    }
  end
end
