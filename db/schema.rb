# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150528055308) do

  create_table "atlases", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.string   "slug",           limit: 8,                                null: false
    t.text     "title",          limit: 65535
    t.text     "text",           limit: 65535
    t.float    "west",           limit: 53,                               null: false
    t.float    "south",          limit: 53,                               null: false
    t.float    "east",           limit: 53,                               null: false
    t.float    "north",          limit: 53,                               null: false
    t.integer  "zoom",           limit: 1
    t.integer  "rows",           limit: 1,                                null: false
    t.integer  "cols",           limit: 1,                                null: false
    t.string   "provider",       limit: 255
    t.string   "paper_size",     limit: 6,          default: "letter",    null: false
    t.string   "orientation",    limit: 9,          default: "portrait",  null: false
    t.string   "layout",         limit: 9,          default: "full-page", null: false
    t.string   "pdf_url",        limit: 255
    t.string   "preview_url",    limit: 255
    t.string   "country_name",   limit: 64
    t.integer  "country_woeid",  limit: 4
    t.string   "region_name",    limit: 64
    t.integer  "region_woeid",   limit: 4
    t.string   "place_name",     limit: 128
    t.integer  "place_woeid",    limit: 4
    t.float    "progress",       limit: 24
    t.boolean  "private",                           default: false,       null: false
    t.integer  "cloned_from",    limit: 4
    t.integer  "refreshed_from", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "composed_at"
    t.datetime "failed_at"
    t.string   "workflow_state", limit: 255
  end

  add_index "atlases", ["cloned_from"], name: "index_atlases_on_cloned_from", using: :btree
  add_index "atlases", ["private"], name: "index_atlases_on_private", using: :btree
  add_index "atlases", ["refreshed_from"], name: "index_atlases_on_refreshed_from", using: :btree
  add_index "atlases", ["slug"], name: "index_atlases_on_slug", unique: true, using: :btree
  add_index "atlases", ["user_id"], name: "index_atlases_on_user_id", using: :btree

  create_table "mbtiles", force: :cascade do |t|
    t.integer  "user_id",        limit: 4,                   null: false
    t.boolean  "private",                    default: false, null: false
    t.string   "url",            limit: 255
    t.string   "uploaded_file",  limit: 255
    t.integer  "min_zoom",       limit: 4
    t.integer  "max_zoom",       limit: 4
    t.integer  "center_zoom",    limit: 4
    t.integer  "center_x_coord", limit: 4
    t.integer  "center_y_coord", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mbtiles", ["user_id"], name: "index_mbtiles_on_user_id", using: :btree

  create_table "notes", force: :cascade do |t|
    t.integer  "snapshot_id", limit: 4,                      null: false
    t.integer  "user_id",     limit: 4
    t.integer  "note_number", limit: 4,          default: 0, null: false
    t.text     "note",        limit: 65535
    t.float    "latitude",    limit: 53
    t.float    "longitude",   limit: 53
    t.text     "geometry",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notes", ["snapshot_id"], name: "index_notes_on_snapshot_id", using: :btree
  add_index "notes", ["user_id"], name: "index_notes_on_user_id", using: :btree

  create_table "pages", force: :cascade do |t|
    t.integer  "atlas_id",      limit: 4,   null: false
    t.string   "page_number",   limit: 5,   null: false
    t.float    "west",          limit: 53,  null: false
    t.float    "south",         limit: 53,  null: false
    t.float    "east",          limit: 53,  null: false
    t.float    "north",         limit: 53,  null: false
    t.integer  "zoom",          limit: 1
    t.string   "provider",      limit: 255
    t.string   "preview_url",   limit: 255
    t.string   "country_name",  limit: 64
    t.integer  "country_woeid", limit: 4
    t.string   "region_name",   limit: 64
    t.string   "place_name",    limit: 128
    t.integer  "place_woeid",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "composed_at"
    t.string   "pdf_url",       limit: 255
  end

  add_index "pages", ["atlas_id", "page_number"], name: "index_pages_on_atlas_id_and_page_number", using: :btree
  add_index "pages", ["atlas_id"], name: "index_pages_on_print_id", using: :btree

  create_table "snapshots", force: :cascade do |t|
    t.string   "slug",               limit: 8,                          null: false
    t.integer  "user_id",            limit: 4
    t.integer  "page_id",            limit: 4
    t.text     "page_url",           limit: 65535
    t.float    "min_row",            limit: 24
    t.float    "max_row",            limit: 24
    t.float    "min_column",         limit: 24
    t.float    "max_column",         limit: 24
    t.integer  "min_zoom",           limit: 4
    t.integer  "max_zoom",           limit: 4
    t.text     "description",        limit: 65535
    t.boolean  "private",                               default: false, null: false
    t.string   "has_geotiff",        limit: 3,          default: "no"
    t.string   "has_geojpeg",        limit: 3,          default: "no"
    t.string   "base_url",           limit: 255
    t.string   "uploaded_file",      limit: 255
    t.string   "country_name",       limit: 64
    t.integer  "country_woeid",      limit: 4
    t.string   "region_name",        limit: 64
    t.integer  "region_woeid",       limit: 4
    t.string   "place_name",         limit: 128
    t.integer  "place_woeid",        limit: 4
    t.float    "progress",           limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "decoded_at"
    t.string   "scene_file_name",    limit: 255
    t.string   "scene_content_type", limit: 255
    t.integer  "scene_file_size",    limit: 4
    t.datetime "scene_updated_at"
    t.string   "s3_scene_url",       limit: 255
    t.integer  "atlas_id",           limit: 4
    t.float    "west",               limit: 24
    t.float    "south",              limit: 24
    t.float    "east",               limit: 24
    t.float    "north",              limit: 24
    t.integer  "zoom",               limit: 4
    t.string   "geotiff_url",        limit: 255
    t.datetime "failed_at"
    t.string   "workflow_state",     limit: 255
  end

  add_index "snapshots", ["slug"], name: "index_snapshots_on_slug", unique: true, using: :btree
  add_index "snapshots", ["user_id"], name: "index_snapshots_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "username",               limit: 32
    t.string   "legacy_password",        limit: 40
    t.string   "email",                  limit: 255
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  execute "DROP FUNCTION IF EXISTS field(anyelement, VARIADIC anyarray)"
  execute <<-EOQ
CREATE FUNCTION field(anyelement, VARIADIC anyarray) RETURNS integer AS $$
SELECT
  COALESCE(
   ( SELECT i FROM generate_subscripts($2, 1) gs(i)
     WHERE $2[i] = $1 ),
   0);
$$ LANGUAGE SQL STABLE
EOQ

end
