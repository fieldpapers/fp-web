class UpdateForeignKeys < ActiveRecord::Migration
  def up
    add_index :atlases, :slug
    add_index :atlases, :user_slug
    add_index :atlases, :cloned_from_slug
    add_index :atlases, :refreshed_from_slug
    add_index :pages, :print_slug
    add_index :snapshots, :slug
    add_index :users, :slug

    execute <<-EOQ
      UPDATE atlases
      LEFT JOIN users ON atlases.user_slug = users.slug
      SET atlases.user_id = users.id
      WHERE atlases.user_slug IS NOT NULL
    EOQ

    execute "ALTER TABLE atlases ADD COLUMN cloned_from INT AFTER private"
    execute "ALTER TABLE atlases ADD COLUMN refreshed_from INT AFTER cloned_from_slug"

    execute <<-EOQ
      UPDATE atlases
      LEFT JOIN atlases a2 ON atlases.cloned_from_slug = a2.slug
      SET atlases.cloned_from = a2.id
      WHERE atlases.cloned_from_slug IS NOT NULL
    EOQ

    execute <<-EOQ
      UPDATE atlases
      LEFT JOIN atlases a2 ON atlases.refreshed_from_slug = a2.slug
      SET atlases.refreshed_from = a2.id
      WHERE atlases.refreshed_from_slug IS NOT NULL
    EOQ

    execute <<-EOQ
      UPDATE mbtiles
      LEFT JOIN users ON mbtiles.user_slug = users.slug
      SET mbtiles.user_id = users.id
      WHERE mbtiles.user_slug IS NOT NULL
    EOQ

    execute <<-EOQ
      UPDATE notes
      LEFT JOIN snapshots ON notes.scan_slug = snapshots.slug
      SET notes.snapshot_id = snapshots.id
      WHERE notes.scan_slug IS NOT NULL
    EOQ

    execute <<-EOQ
      UPDATE notes
      LEFT JOIN users ON notes.user_slug = users.slug
      SET notes.user_id = users.id
      WHERE notes.user_slug IS NOT NULL
    EOQ

    rename_column :pages, :print_id, :atlas_id

    execute <<-EOQ
      UPDATE pages
      JOIN atlases ON pages.print_slug = atlases.slug
      SET pages.atlas_id = atlases.id
    EOQ

    execute <<-EOQ
      UPDATE snapshots
      LEFT JOIN pages ON snapshots.print_slug = pages.print_slug
        AND snapshots.print_page_number = pages.page_number
      SET snapshots.page_id = pages.id
    EOQ

    execute <<-EOQ
      UPDATE snapshots
      LEFT JOIN users ON snapshots.user_slug = users.slug
      SET snapshots.user_id = users.id
      WHERE snapshots.user_slug IS NOT NULL
    EOQ

    add_index :atlases, :user_id
    add_index :atlases, :cloned_from
    add_index :atlases, :refreshed_from
    add_index :notes, :snapshot_id
    add_index :notes, :user_id
    add_index :pages, [:atlas_id, :page_number]

    remove_column :atlases, :user_slug
    remove_column :atlases, :cloned_from_slug
    remove_column :atlases, :refreshed_from_slug
    remove_column :mbtiles, :slug
    remove_column :mbtiles, :user_slug
    remove_column :notes, :scan_slug
    remove_column :notes, :user_slug
    remove_column :pages, :print_slug
    remove_column :pages, :user_slug
    remove_column :snapshots, :print_slug
    remove_column :snapshots, :print_page_number
    remove_column :snapshots, :user_slug
    remove_column :users, :slug
  end
end
