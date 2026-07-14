class DropMbtiles < ActiveRecord::Migration[7.0]
  # The mbtiles feature (user-uploaded MBTiles basemaps) never shipped past a
  # "Coming soon" UI stub, removed in 2015 (80a183a). The 26 remaining rows are
  # orphaned legacy data from the pre-Rails schema; no model or code references
  # the table. Dropping it also removes the duplicate "user_id" index name that
  # blocks db:schema:load on Postgres.
  def up
    drop_table :mbtiles
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
