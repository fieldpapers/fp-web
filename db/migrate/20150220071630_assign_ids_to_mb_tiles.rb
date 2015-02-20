class AssignIdsToMbTiles < ActiveRecord::Migration
  def up
    execute <<-EOQ
      CREATE TABLE new_mbtiles (
        id INT NOT NULL AUTO_INCREMENT,
        user_id INT NOT NULL,
        private BOOLEAN NOT NULL DEFAULT FALSE,
        PRIMARY KEY(id),
        KEY(user_id)
      )
      SELECT
        id AS slug,
        -1 AS user_id,
        user_id AS user_slug,
        false AS private,
        url,
        uploaded_file,
        min_zoom,
        max_zoom,
        center_zoom,
        center_x_coord,
        center_y_coord,
        CAST(created AS datetime) AS created_at,
        CAST(created AS datetime) AS updated_at
      FROM mbtiles
    EOQ

    drop_table :mbtiles
    rename_table :new_mbtiles, :mbtiles
  end
end
