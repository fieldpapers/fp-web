class AddGeoTiffUrlToSnapshots < ActiveRecord::Migration
  def up
    change_table(:snapshots) do |t|
      t.string :geotiff_url
    end

    execute <<-EOQ
      DELETE FROM snapshots
      WHERE base_url IS NULL
    EOQ

    execute <<-EOQ
      UPDATE snapshots
      SET geotiff_url = CONCAT('http://s3.amazonaws.com/files.fieldpapers.org/snapshots/', slug, '/walking-paper-', slug, '.tif')
    EOQ
  end
end
