class DropGeoJpegBoundsFromSnapshots < ActiveRecord::Migration
  def change
    remove_column :snapshots, :geojpeg_bounds
  end
end
