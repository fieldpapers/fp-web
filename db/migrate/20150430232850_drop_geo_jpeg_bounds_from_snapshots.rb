class DropGeoJpegBoundsFromSnapshots < ActiveRecord::Migration[4.2]
  def change
    remove_column :snapshots, :geojpeg_bounds
  end
end
