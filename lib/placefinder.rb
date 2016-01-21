require "faraday"
require "faraday_middleware"

class Placefinder
  class PlaceNotFoundException < Exception
    attr_reader :place

    def initialize(message, place)
      super(message)
      @place = place
    end
  end

  def self.query(q)
    client = Faraday.new(url: "https://search.mapzen.com/v1/search") do |faraday|
      faraday.response :json, content_type: /\bjson$/

      faraday.adapter Faraday.default_adapter
    end

    rsp = client.get("", {
      api_key: "blah",
      text: q,
    })

    case rsp.status
    when 200
      results = rsp.body["features"]

      raise PlaceNotFoundException.new("'#{q}' could not be found", q) if results.empty?

      result = results.first

      zoom = case result["properties"]["layer"]
        when "neighborhood"
          14
        when "locality"
          12
        when "region"
          8
        when "country"
          6
        else
          10
        end

      return zoom, result["geometry"]["coordinates"][0], result["geometry"]["coordinates"][1]
    else
      raise rsp.body
    end
  end
end
