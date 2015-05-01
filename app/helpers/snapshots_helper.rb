module SnapshotsHelper

  # Used in CSV output
  def snapshot_person_href(snapshot)
    if snapshot.user_id
      snapshot_url(user: snapshot.user_id)
    end
  end

  def tilejson_url(snapshot)
    "#{FieldPapers::TILE_BASE_URL}/snapshots/#{snapshot.slug}/index.json"
  end

end
