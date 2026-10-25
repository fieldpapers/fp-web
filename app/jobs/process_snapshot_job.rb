# Identifies the atlas page in a snapshot's image from its QR code, then
# georeferences the image using that page's bounds.
class ProcessSnapshotJob < FpTasksJob
  def perform(snapshot_id)
    snapshot = record
    return unless snapshot.incomplete?

    href = FpTasks.decode_qr(snapshot)
    snapshot.update_columns(page_url: href, progress: 0.5)

    page = Snapshot.page_for_href(href)
    if page.nil?
      logger.warn("Failing Snapshot #{snapshot.slug}: no page for QR code #{href}")
      snapshot.mark_failed!
      return
    end

    geotiff_url = FpTasks.georeference(snapshot, page)
    snapshot.mark_complete!(
      page_id: page.id,
      geotiff_url: geotiff_url,
      west: page.west,
      south: page.south,
      east: page.east,
      north: page.north,
      zoom: page.zoom,
      private: page.atlas.private,
      progress: 1,
    )
  end

  def record
    @record ||= Snapshot.unscoped.find(arguments.first)
  end
end
