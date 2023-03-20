class AssignIdsToNotes < ActiveRecord::Migration[4.2]
  def up
    execute <<-EOQ
      CREATE TABLE notes (
        id INT NOT NULL AUTO_INCREMENT,
        snapshot_id INT NOT NULL,
        user_id INT,
        PRIMARY KEY(id)
      )
      SELECT
        scan_id AS scan_slug,
        user_id AS user_slug,
        -1 AS snapshot_id,
        NULL AS user_id,
        note_number,
        CONVERT(CAST(CONVERT(note USING latin1) AS BINARY) USING utf8) note, -- fix encoding issues
        latitude,
        longitude,
        geometry,
        CAST(created AS datetime) AS created_at,
        CAST(created AS datetime) AS updated_at
      FROM scan_notes
    EOQ

    drop_table :scan_notes
  end
end
