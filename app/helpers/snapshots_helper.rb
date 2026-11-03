module SnapshotsHelper

  def tilejson_url(snapshot)
    "#{FieldPapers::TILE_BASE_URL}/snapshots/#{snapshot.slug}/index.json"
  end
end
