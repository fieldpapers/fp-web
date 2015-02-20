class ReversePropagateAtlasMetadata < ActiveRecord::Migration
  def change
    execute <<-EOQ
      CREATE TEMPORARY TABLE atlas_metadata
      SELECT
        print_slug,
        zoom,
        provider
      FROM pages
      GROUP BY print_slug
    EOQ

    execute <<-EOQ
      UPDATE atlas_metadata
      LEFT JOIN atlases ON atlases.slug = atlas_metadata.print_slug
      SET atlases.zoom = atlas_metadata.zoom,
        atlases.provider = atlas_metadata.zoom
    EOQ
  end
end
