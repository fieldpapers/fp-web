class AssignIdsToAtlases < ActiveRecord::Migration
  def up
    # clear out titles containing invalid characters (manually identified with
    # the help of
    #   https://www.blueboxcloud.com/insight/blog-article/getting-out-of-mysql-character-set-hell
    execute <<-EOQ
      UPDATE atlases
      SET title = NULL 
      WHERE id IN ('38lmc9f8', '79vdl2b2', 'c65f7wx8', 'mcrtnkns', 'mzdw4g49', 'v4cx7kl9', 'vqhskvtk', 'wznc8s69', 'xm6gkzpx')
    EOQ

    execute <<-EOQ
      CREATE TABLE new_atlases (
        id INT NOT NULL AUTO_INCREMENT,
        user_id INT,
        west DOUBLE NOT NULL,
        south DOUBLE NOT NULL,
        east DOUBLE NOT NULL,
        north DOUBLE NOT NULL,
        zoom TINYINT,
        rows TINYINT NOT NULL,
        cols TINYINT NOT NULL,
        provider VARCHAR(255),
        paper_size ENUM('letter', 'a4', 'a3') NOT NULL DEFAULT 'letter',
        orientation ENUM('portrait', 'landscape') NOT NULL DEFAULT 'portrait',
        layout ENUM('half-page', 'full-page') NOT NULL DEFAULT 'full-page',
        private BOOL NOT NULL DEFAULT false,
        PRIMARY KEY(id),
        KEY(slug),
        KEY(user_slug),
        KEY(private)
      )
      SELECT
        id AS slug,
        user_id AS user_slug,
        CONVERT(CAST(CONVERT(title USING latin1) AS BINARY) USING utf8) title, -- fix encoding issues
        CONVERT(CAST(CONVERT(text USING latin1) AS BINARY) USING utf8) text, -- fix encoding issues
        west,
        south,
        east,
        north,
        zoom,
        rows,
        cols,
        provider,
        paper_size,
        orientation,
        layout,
        pdf_url,
        preview_url,
        country_name,
        country_woeid,
        region_name,
        region_woeid,
        place_name,
        place_woeid,
        progress,
        private,
        cloned AS cloned_from_slug,
        refreshed AS refreshed_from_slug,
        CAST(created_at AS datetime) AS created_at,
        updated_at,
        CAST(composed_at AS datetime) AS composed_at
      FROM atlases
      WHERE west IS NOT NULL
        AND south IS NOT NULL
        AND east IS NOT NULL
        AND north IS NOT NULL
    EOQ

    drop_table :atlases
    rename_table :new_atlases, :atlases
  end
end
