class ReversePropagateAtlasMetadata < ActiveRecord::Migration[4.2]
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
        atlases.provider = atlas_metadata.provider
    EOQ
  end
end
