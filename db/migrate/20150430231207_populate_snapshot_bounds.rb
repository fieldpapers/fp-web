class PopulateSnapshotBounds < ActiveRecord::Migration
  def up
    execute <<-EOQ
      UPDATE snapshots
      SET south=SUBSTRING_INDEX(geojpeg_bounds, ',', 1),
        west=SUBSTRING_INDEX(SUBSTRING_INDEX(geojpeg_bounds, ',', 2), ',', -1),
        north=SUBSTRING_INDEX(SUBSTRING_INDEX(geojpeg_bounds, ',', -2), ',', 1),
        east=SUBSTRING_INDEX(geojpeg_bounds, ',', -1),
        zoom=min_zoom + 3
    EOQ
  end
end
