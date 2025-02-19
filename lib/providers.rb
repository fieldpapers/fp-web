# Base maps available for Fieldpapers
#
require "json"

class Providers
  # Use layers <key>
  def self.default
    self.layers.keys.first
  end

  def self.options()
    self.layers.map do |k, v|
      [v['label'], v['template']]
    end
  end

  # Get the ID of the provider that corresponds to the
  # given URL (which may be saved in the database).
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
      return provider_layer[0]['template']
    end
    url
  end

  def self.layers
    # For layer options see: http://leafletjs.com/reference.html#tilelayer
    # templates are (currently) expected to be ModestMaps-formatted, which means
    # capital letters for placeholders
    @layers ||= JSON.parse(File.read("config/providers.json"))
  end

end
