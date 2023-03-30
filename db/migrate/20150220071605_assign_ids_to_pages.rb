class AssignIdsToPages < ActiveRecord::Migration[4.2]
  def change
    execute <<-EOQ
      CREATE TABLE new_pages (
        id INT NOT NULL AUTO_INCREMENT,
        print_id INT NOT NULL,
        west DOUBLE NOT NULL,
        south DOUBLE NOT NULL,
        east DOUBLE NOT NULL,
        north DOUBLE NOT NULL,
        zoom TINYINT,
        provider VARCHAR(255),
        PRIMARY KEY(id),
        KEY(print_id)
      )
      SELECT
        -1 AS print_id,
        print_id AS print_slug,
        user_id AS user_slug,
        page_number,
        text,
        west,
        south,
        east,
        north,
        zoom,
        provider,
        preview_url,
        country_name,
        country_woeid,
        region_name,
        place_name,
        place_woeid,
        CAST(created_at AS datetime) AS created_at,
        updated_at,
        CAST(composed_at AS datetime) AS composed_at
      FROM pages
      WHERE west IS NOT NULL
        AND south IS NOT NULL
        AND east IS NOT NULL
        AND north IS NOT NULL
    EOQ

    drop_table :pages
    rename_table :new_pages, :pages
  end
end
