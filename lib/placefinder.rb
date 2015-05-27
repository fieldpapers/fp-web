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
    client = Faraday.new(url: "http://query.yahooapis.com/v1/public/yql") do |faraday|
      faraday.response :json, content_type: /\bjson$/

      faraday.adapter Faraday.default_adapter
    end

    rsp = client.get("", {
      format: "json",
      q: "select * from geo.placefinder where text='#{q}'"
    })

    case rsp.status
    when 200
      results = rsp.body["query"]["results"]

      raise PlaceNotFoundException.new("'#{q}' could not be found", q) unless results

      result = results["Result"]
      result = result.first if result.is_a?(Array)

      zoom = case
        when result["street"]
          14
        when result["city"]
          12
        when result["state"]
          8
        when result["country"]
          6
        else
          10
        end

      return zoom, result["longitude"], result["latitude"]
    else
      raise rsp.body
    end
  end
end
