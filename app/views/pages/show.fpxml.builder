xml.instruct!
xml.print id: "#{@page.atlas.slug}/#{@page.page_number}", user: @page.atlas.creator.try(:slug), href: atlas_page_atlas_url(@page.atlas, @page.page_number) do
  xml.paper size: @page.atlas.paper_size, orientation: @page.atlas.orientation, layout: @page.atlas.layout
  xml.provider @page.provider
  xml.pdf href: @page.atlas.pdf_url

  xml.bounds do
    xml.north @page.north
    xml.south @page.south
    xml.east @page.east
    xml.west @page.west
  end

  xml.center do
    xml.latitude @page.latitude
    xml.longitude @page.longitude
    xml.zoom @page.zoom
  end

  xml.country @page.country_name, woeid: @page.country_woeid
  xml.region @page.region_name, woeid: @page.region_woeid
  xml.place @page.place_name, woeid: @page.place_woeid
end
