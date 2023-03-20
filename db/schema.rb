# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2015_05_28_055308) do
  create_table "atlases", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "slug", limit: 8, null: false
    t.text "title", size: :long
    t.text "text", size: :long
    t.float "west", limit: 53, null: false
    t.float "south", limit: 53, null: false
    t.float "east", limit: 53, null: false
    t.float "north", limit: 53, null: false
    t.integer "zoom", limit: 1
    t.integer "rows", limit: 1, null: false
    t.integer "cols", limit: 1, null: false
    t.string "provider"
    t.string "paper_size", limit: 6, default: "letter", null: false
    t.string "orientation", limit: 9, default: "portrait", null: false
    t.string "layout", limit: 9, default: "full-page", null: false
    t.string "pdf_url"
    t.string "preview_url"
    t.string "country_name", limit: 64
    t.integer "country_woeid"
    t.string "region_name", limit: 64
    t.integer "region_woeid"
    t.string "place_name", limit: 128
    t.integer "place_woeid"
    t.float "progress"
    t.boolean "private", default: false, null: false
    t.integer "cloned_from"
    t.integer "refreshed_from"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "composed_at"
    t.datetime "failed_at"
    t.string "workflow_state"
    t.index ["cloned_from"], name: "index_atlases_on_cloned_from"
    t.index ["private"], name: "private"
    t.index ["refreshed_from"], name: "index_atlases_on_refreshed_from"
    t.index ["slug"], name: "index_atlases_on_slug", unique: true
    t.index ["slug"], name: "slug"
    t.index ["user_id"], name: "index_atlases_on_user_id"
  end

  create_table "mbtiles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.boolean "private", default: false, null: false
    t.string "url"
    t.string "uploaded_file"
    t.integer "min_zoom"
    t.integer "max_zoom"
    t.integer "center_zoom"
    t.integer "center_x_coord"
    t.integer "center_y_coord"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "user_id"
  end

  create_table "notes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "snapshot_id", null: false
    t.integer "user_id"
    t.integer "note_number", default: 0, null: false
    t.text "note", size: :long
    t.float "latitude", limit: 53
    t.float "longitude", limit: 53
    t.text "geometry"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["snapshot_id"], name: "index_notes_on_snapshot_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "pages", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "atlas_id", null: false
    t.string "page_number", limit: 5, null: false
    t.float "west", limit: 53, null: false
    t.float "south", limit: 53, null: false
    t.float "east", limit: 53, null: false
    t.float "north", limit: 53, null: false
    t.integer "zoom", limit: 1
    t.string "provider"
    t.string "preview_url"
    t.string "country_name", limit: 64
    t.integer "country_woeid"
    t.string "region_name", limit: 64
    t.string "place_name", limit: 128
    t.integer "place_woeid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "composed_at"
    t.string "pdf_url"
    t.index ["atlas_id", "page_number"], name: "index_pages_on_atlas_id_and_page_number"
    t.index ["atlas_id"], name: "print_id"
  end

  create_table "snapshots", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "slug", limit: 8, null: false
    t.integer "user_id"
    t.integer "page_id"
    t.text "page_url"
    t.float "min_row"
    t.float "max_row"
    t.float "min_column"
    t.float "max_column"
    t.integer "min_zoom"
    t.integer "max_zoom"
    t.text "description", size: :long
    t.boolean "private", default: false, null: false
    t.string "has_geotiff", limit: 3, default: "no"
    t.string "has_geojpeg", limit: 3, default: "no"
    t.string "base_url"
    t.string "uploaded_file"
    t.string "country_name", limit: 64
    t.integer "country_woeid"
    t.string "region_name", limit: 64
    t.integer "region_woeid"
    t.string "place_name", limit: 128
    t.integer "place_woeid"
    t.float "progress"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "decoded_at"
    t.string "scene_file_name"
    t.string "scene_content_type"
    t.integer "scene_file_size"
    t.datetime "scene_updated_at"
    t.string "s3_scene_url"
    t.integer "atlas_id"
    t.float "west"
    t.float "south"
    t.float "east"
    t.float "north"
    t.integer "zoom"
    t.string "geotiff_url"
    t.datetime "failed_at"
    t.string "workflow_state"
    t.index ["slug"], name: "index_snapshots_on_slug", unique: true
    t.index ["user_id"], name: "user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "username", limit: 32
    t.string "legacy_password", limit: 40
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["confirmation_token"], name: "confirmation_token", unique: true
    t.index ["email"], name: "email", unique: true
    t.index ["reset_password_token"], name: "reset_password_token", unique: true
    t.index ["username"], name: "username", unique: true
  end

end
