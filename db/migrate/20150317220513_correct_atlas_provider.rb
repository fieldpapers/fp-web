class CorrectAtlasProvider < ActiveRecord::Migration[4.2]
  def change
    execute <<-EOQ
      CREATE TEMPORARY TABLE atlas_metadata2
      SELECT
        atlas_id,
        zoom,
        provider
      FROM pages
      GROUP BY atlas_id
    EOQ

    execute <<-EOQ
      UPDATE atlas_metadata2
      LEFT JOIN atlases ON atlases.id = atlas_metadata2.atlas_id
      SET atlases.zoom = atlas_metadata2.zoom,
        atlases.provider = atlas_metadata2.provider
    EOQ
  end
end
