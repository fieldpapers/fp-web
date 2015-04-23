xml.instruct!
xml.print id: @atlas.slug, user: @atlas.creator.try(:slug), href: atlas_url(@atlas) do
  xml.paper size: @atlas.paper_size, orientation: @atlas.orientation, layout: @atlas.layout
  xml.provider @atlas.provider
  xml.pdf href: @atlas.pdf_url

  xml.bounds do
    xml.north @atlas.north
    xml.south @atlas.south
    xml.east @atlas.east
    xml.west @atlas.west
  end

  xml.center do
    xml.latitude @atlas.latitude
    xml.longitude @atlas.longitude
    xml.zoom @atlas.zoom
  end

  xml.country @atlas.country_name, woeid: @atlas.country_woeid
  xml.region @atlas.region_name, woeid: @atlas.region_woeid
  xml.place @atlas.place_name, woeid: @atlas.place_woeid
end
