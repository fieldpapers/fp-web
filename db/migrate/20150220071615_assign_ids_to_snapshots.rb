class AssignIdsToSnapshots < ActiveRecord::Migration[4.2]
  def up
    execute <<-EOQ
      CREATE TABLE new_snapshots (
        id INT NOT NULL AUTO_INCREMENT,
        user_id INT,
        page_id INT,
        private BOOLEAN NOT NULL DEFAULT false,
        PRIMARY KEY(id),
        KEY(user_id)
      )
      SELECT
        id AS slug,
        NULL AS user_id,
        NULL AS page_id,
        print_id AS print_slug,
        user_id AS user_slug,
        print_page_number,
        print_href,
        min_row,
        max_row,
        min_column,
        max_column,
        min_zoom,
        max_zoom,
        CONVERT(CAST(CONVERT(description USING latin1) AS BINARY) USING utf8) description, -- fix encoding issues
        false AS private,
        has_geotiff,
        has_geojpeg,
        base_url,
        uploaded_file,
        geojpeg_bounds,
        decoding_json,
        country_name,
        country_woeid,
        region_name,
        region_woeid,
        place_name,
        place_woeid,
        failed,
        progress,
        CAST(created_at AS datetime) AS created_at,
        updated_at,
        CAST(decoded_at AS datetime) AS decoded_at
      FROM snapshots
    EOQ

    drop_table :snapshots
    rename_table :new_snapshots, :snapshots
  end
end
