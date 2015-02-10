create extension mysql_fdw;
create extension postgis;
create server mysql_server foreign data wrapper mysql_fdw options (host '192.168.59.103', port '3306');
create user mapping for seth server mysql_server options (username 'root', password 'fig');

create foreign table remote_prints (
  "id" text NOT NULL,
  "title" text,
  "form_id" text DEFAULT NULL,
  "north" numeric DEFAULT NULL,
  "south" numeric DEFAULT NULL,
  "east" numeric DEFAULT NULL,
  "west" numeric DEFAULT NULL,
  "zoom" integer DEFAULT NULL,
  "paper_size" text DEFAULT 'letter',
  "orientation" text DEFAULT 'portrait',
  "layout" text DEFAULT 'full-page',
  "provider" text DEFAULT NULL,
  "pdf_url" text DEFAULT NULL,
  "preview_url" text DEFAULT NULL,
  "geotiff_url" text DEFAULT NULL,
  "atlas_pages" text,
  "country_name" text DEFAULT NULL,
  "country_woeid" integer DEFAULT NULL,
  "region_name" text DEFAULT NULL,
  "region_woeid" integer DEFAULT NULL,
  "place_name" text DEFAULT NULL,
  "place_woeid" integer DEFAULT NULL,
  "user_id" text DEFAULT NULL,
  "created" timestamp NOT NULL DEFAULT NOW(),
  "composed" timestamp,
  "progress" float DEFAULT NULL,
  "private" boolean NOT NULL,
  "text" text,
  "cloned" text DEFAULT NULL,
  "refreshed" text DEFAULT NULL
)
server mysql_server
  options (dbname 'fieldpapers_development', table_name 'prints');

create foreign table remote_pages (
  "print_id" text NOT NULL,
  "page_number" text NOT NULL,
  "text" text,
  "north" numeric DEFAULT NULL,
  "south" numeric DEFAULT NULL,
  "east" numeric DEFAULT NULL,
  "west" numeric DEFAULT NULL,
  "zoom" integer DEFAULT NULL,
  "provider" text DEFAULT NULL,
  "preview_url" text DEFAULT NULL,
  "country_name" text DEFAULT NULL,
  "country_woeid" integer DEFAULT NULL,
  "region_name" text DEFAULT NULL,
  "region_woeid" integer DEFAULT NULL,
  "place_name" text DEFAULT NULL,
  "place_woeid" integer DEFAULT NULL,
  "user_id" text NOT NULL,
  "created" timestamp NOT NULL DEFAULT NOW(),
  "composed" timestamp
)
server mysql_server
  options (dbname 'fieldpapers_development', table_name 'pages');

create view atlases AS
  SELECT
    NULL::integer AS id,
    id AS slug,
    title,
    form_id,
    ST_MakeEnvelope(west, south, east, north, 4326) AS bbox,
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
    composed,
    progress,
    private,
    text,
    cloned,
    refreshed
  FROM remote_prints;

create view pages AS
  SELECT
    NULL::integer AS id,
    print_id,
    page_number,
    text,
    ST_MakeEnvelope(west, south, east, north, 4326) AS bbox,
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
    created,
    composed
  FROM remote_pages;
