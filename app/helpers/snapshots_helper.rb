module SnapshotsHelper

  # Used in CSV output
  def snapshot_person_href(snapshot)
    if snapshot.user_id
      snapshot_url(user: snapshot.user_id)
    end
  end

end
