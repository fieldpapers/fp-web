class CorrectAtlasProvider < ActiveRecord::Migration
  def change
    execute <<-EOQ
      CREATE TEMPORARY TABLE atlas_metadata
      SELECT
        atlas_id,
        zoom,
        provider
      FROM pages
      GROUP BY atlas_id
    EOQ

    execute <<-EOQ
      UPDATE atlas_metadata
      LEFT JOIN atlases ON atlases.id = atlas_metadata.atlas_id
      SET atlases.zoom = atlas_metadata.zoom,
        atlases.provider = atlas_metadata.provider
    EOQ
  end
end
