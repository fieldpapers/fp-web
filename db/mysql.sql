drop view if exists new_atlases;
create view new_atlases AS
  SELECT
    0 AS id,
    id AS slug,
    title,
    form_id,
    west,
    south,
    east,
    north,
    zoom,
    paper_size,
    orientation,
    layout,
    provider,
    pdf_url,
    preview_url,
    geotiff_url,
    atlas_pages,
    country_name,
    country_woeid,
    region_name,
    region_woeid,
    place_name,
    place_woeid,
    user_id,
    created AS created_at,
    created AS updated_at,
    composed AS composed_at,
    progress,
    private,
    text,
    cloned,
    refreshed
  FROM prints;

drop view if exists new_pages;
create view new_pages AS
  SELECT
    0 AS id,
    print_id,
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
    region_woeid,
    place_name,
    place_woeid,
    user_id,
    created AS created_at,
    composed
  FROM pages;

drop view if exists new_users;
create view new_users AS
  SELECT
    0 AS id,
    id AS slug,
    name,
    password,
    email,
    created AS created_at,
    activated
  FROM users;

drop view if exists new_snapshots;
create view new_snapshots AS
  SELECT
    0 AS id,
    id AS slug,
    print_id,
    print_page_number,
    print_href,
    min_row,
    min_column,
    min_zoom,
    max_row,
    max_column,
    max_zoom,
    description,
    is_private,
    will_edit,
    has_geotiff,
    has_geojpeg,
    has_stickers,
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
    user_id,
    created AS created_at,
    decoded AS decoded_at,
    failed,
    progress
  FROM scans;
