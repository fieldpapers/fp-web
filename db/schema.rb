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

ActiveRecord::Schema.define(version: 20150216203144) do

  create_table "atlases", force: :cascade do |t|
    t.text     "title",         limit: 65535
    t.string   "form_id",       limit: 8
    t.float    "north",         limit: 53
    t.float    "south",         limit: 53
    t.float    "east",          limit: 53
    t.float    "west",          limit: 53
    t.integer  "zoom",          limit: 4
    t.string   "paper_size",    limit: 6,        default: "letter"
    t.string   "orientation",   limit: 9,        default: "portrait"
    t.string   "layout",        limit: 9,        default: "full-page"
    t.string   "provider",      limit: 255
    t.string   "pdf_url",       limit: 255
    t.string   "preview_url",   limit: 255
    t.string   "geotiff_url",   limit: 255
    t.string   "country_name",  limit: 64
    t.integer  "country_woeid", limit: 4
    t.string   "region_name",   limit: 64
    t.integer  "region_woeid",  limit: 4
    t.string   "place_name",    limit: 128
    t.integer  "place_woeid",   limit: 4
    t.string   "user_id",       limit: 8
    t.datetime "created_at",                                           null: false
    t.datetime "composed_at",                                          null: false
    t.float    "progress",      limit: 24
    t.integer  "private",       limit: 1,                              null: false
    t.text     "text",          limit: 16777215
    t.string   "cloned",        limit: 20
    t.string   "refreshed",     limit: 20
    t.datetime "updated_at"
    t.integer  "rows",          limit: 4,                              null: false
    t.integer  "cols",          limit: 4,                              null: false
  end

  add_index "atlases", ["private"], name: "prints_private", using: :btree
  add_index "atlases", ["user_id"], name: "user", using: :btree

  create_table "form_fields", id: false, force: :cascade do |t|
    t.string "form_id", limit: 8,                  null: false
    t.string "name",    limit: 255,   default: "", null: false
    t.text   "label",   limit: 65535
    t.string "type",    limit: 8,                  null: false
    t.binary "choices", limit: 65535
  end

  add_index "form_fields", ["form_id"], name: "form", using: :btree

  create_table "forms", force: :cascade do |t|
    t.text     "title",       limit: 65535
    t.text     "form_url",    limit: 65535
    t.string   "http_method", limit: 4
    t.text     "action_url",  limit: 65535
    t.string   "user_id",     limit: 8
    t.datetime "created",                               null: false
    t.datetime "parsed",                                null: false
    t.integer  "failed",      limit: 4,     default: 0
  end

  add_index "forms", ["user_id"], name: "user", using: :btree

  create_table "logs", force: :cascade do |t|
    t.text     "content", limit: 65535
    t.datetime "created",               null: false
  end

  create_table "mbtiles", force: :cascade do |t|
    t.string   "user_id",        limit: 8,                  null: false
    t.datetime "created",                                   null: false
    t.string   "is_private",     limit: 3,   default: "no"
    t.string   "url",            limit: 255
    t.string   "uploaded_file",  limit: 255
    t.integer  "min_zoom",       limit: 4
    t.integer  "max_zoom",       limit: 4
    t.integer  "center_zoom",    limit: 4
    t.integer  "center_x_coord", limit: 4
    t.integer  "center_y_coord", limit: 4
  end

  add_index "mbtiles", ["user_id"], name: "user", using: :btree

  create_table "pages", id: false, force: :cascade do |t|
    t.string   "print_id",      limit: 8,     null: false
    t.string   "page_number",   limit: 5,     null: false
    t.text     "text",          limit: 65535
    t.float    "north",         limit: 53
    t.float    "south",         limit: 53
    t.float    "east",          limit: 53
    t.float    "west",          limit: 53
    t.integer  "zoom",          limit: 4
    t.string   "provider",      limit: 255
    t.string   "preview_url",   limit: 255
    t.string   "country_name",  limit: 64
    t.integer  "country_woeid", limit: 4
    t.string   "region_name",   limit: 64
    t.integer  "region_woeid",  limit: 4
    t.string   "place_name",    limit: 128
    t.integer  "place_woeid",   limit: 4
    t.string   "user_id",       limit: 8,     null: false
    t.datetime "created_at",                  null: false
    t.datetime "composed_at",                 null: false
    t.datetime "updated_at"
  end

  add_index "pages", ["print_id"], name: "print", using: :btree
  add_index "pages", ["user_id"], name: "user", using: :btree

  create_table "scan_notes", id: false, force: :cascade do |t|
    t.string   "scan_id",     limit: 8,                 null: false
    t.integer  "note_number", limit: 4,     default: 0, null: false
    t.text     "note",        limit: 65535
    t.float    "latitude",    limit: 53
    t.float    "longitude",   limit: 53
    t.text     "geometry",    limit: 65535
    t.string   "user_id",     limit: 8,                 null: false
    t.datetime "created",                               null: false
  end

  create_table "snapshots", force: :cascade do |t|
    t.string   "print_id",          limit: 8
    t.string   "print_page_number", limit: 5,                     null: false
    t.text     "print_href",        limit: 65535
    t.float    "min_row",           limit: 24
    t.float    "min_column",        limit: 24
    t.integer  "min_zoom",          limit: 4
    t.float    "max_row",           limit: 24
    t.float    "max_column",        limit: 24
    t.integer  "max_zoom",          limit: 4
    t.text     "description",       limit: 65535
    t.string   "is_private",        limit: 3,     default: "no"
    t.string   "will_edit",         limit: 3,     default: "yes"
    t.string   "has_geotiff",       limit: 3,     default: "no"
    t.string   "has_geojpeg",       limit: 3,     default: "no"
    t.string   "has_stickers",      limit: 3,     default: "no"
    t.string   "base_url",          limit: 255
    t.string   "uploaded_file",     limit: 255
    t.text     "geojpeg_bounds",    limit: 65535
    t.text     "decoding_json",     limit: 65535
    t.string   "country_name",      limit: 64
    t.integer  "country_woeid",     limit: 4
    t.string   "region_name",       limit: 64
    t.integer  "region_woeid",      limit: 4
    t.string   "place_name",        limit: 128
    t.integer  "place_woeid",       limit: 4
    t.string   "user_id",           limit: 8
    t.datetime "created_at",                                      null: false
    t.datetime "decoded_at",                                      null: false
    t.integer  "failed",            limit: 4,     default: 0
    t.float    "progress",          limit: 24
    t.datetime "updated_at"
  end

  add_index "snapshots", ["print_id", "print_page_number"], name: "print", using: :btree
  add_index "snapshots", ["user_id"], name: "user", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "username",               limit: 32
    t.string   "legacy_password",        limit: 40
    t.string   "email",                  limit: 255
    t.datetime "created",                                         null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.datetime "updated_at"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["email"], name: "users_email", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "name", unique: true, using: :btree

end
