json.id @snapshot.slug

json.geotiff do
  json.url @snapshot.geotiff_url
end

json.bbox @snapshot.bbox
json.tiles ["#{FieldPapers::TILE_BASE_URL}/snapshots/#{@snapshot.slug}/{z}/{x}/{y}.png"]
json.tilejson_url tilejson_url(@snapshot)
