xml.instruct!
xml.scan id: @snapshot.slug, user: @snapshot.uploader.try(:slug), href: snapshot_url(@snapshot) do
  xml.provider href: @snapshot.page.provider
  xml.private @snapshot.private
  xml.print id: @snapshot.atlas.slug, user: @snapshot.atlas.creator.try(:slug), href: atlas_url(@snapshot.atlas)

  xml.paper size: @snapshot.atlas.paper_size, orientation: @snapshot.atlas.orientation, layout: @snapshot.atlas.layout
  xml.provider @snapshot.atlas.provider
  xml.pdf href: @snapshot.atlas.pdf_url

  xml.bounds do
    xml.north @snapshot.atlas.north
    xml.south @snapshot.atlas.south
    xml.east @snapshot.atlas.east
    xml.west @snapshot.atlas.west
  end

  xml.center do
    xml.latitude @snapshot.atlas.latitude
    xml.longitude @snapshot.atlas.longitude
    xml.zoom @snapshot.atlas.zoom
  end

  xml.country @snapshot.atlas.country_name, woeid: @snapshot.atlas.country_woeid
  xml.region @snapshot.atlas.region_name, woeid: @snapshot.atlas.region_woeid
  xml.place @snapshot.atlas.place_name, woeid: @snapshot.atlas.place_woeid
end
