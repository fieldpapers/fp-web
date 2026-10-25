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

ActiveRecord::Schema[7.2].define(version: 2026_10_25_120200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "atlases", force: :cascade do |t|
    t.integer "user_id"
    t.string "slug", limit: 8, null: false
    t.text "title"
    t.text "text"
    t.float "west", null: false
    t.float "south", null: false
    t.float "east", null: false
    t.float "north", null: false
    t.integer "zoom", limit: 2
    t.integer "rows", limit: 2, null: false
    t.integer "cols", limit: 2, null: false
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
    t.index ["cloned_from"], name: "index_atlases_on_cloned_from"
    t.index ["created_at"], name: "index_atlases_on_created_at"
    t.index ["private"], name: "private"
    t.index ["refreshed_from"], name: "index_atlases_on_refreshed_from"
    t.index ["slug"], name: "index_atlases_on_slug", unique: true
    t.index ["slug"], name: "slug"
    t.index ["user_id"], name: "index_atlases_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.integer "snapshot_id", null: false
    t.integer "user_id"
    t.integer "note_number", default: 0, null: false
    t.text "note"
    t.float "latitude"
    t.float "longitude"
    t.text "geometry"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["snapshot_id"], name: "index_notes_on_snapshot_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "pages", force: :cascade do |t|
    t.integer "atlas_id", null: false
    t.string "page_number", limit: 5, null: false
    t.float "west", null: false
    t.float "south", null: false
    t.float "east", null: false
    t.float "north", null: false
    t.integer "zoom", limit: 2
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

  create_table "snapshots", force: :cascade do |t|
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
    t.text "description"
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
    t.index ["created_at"], name: "index_snapshots_on_created_at"
    t.index ["page_id"], name: "index_snapshots_on_page_id"
    t.index ["slug"], name: "index_snapshots_on_slug", unique: true
    t.index ["user_id"], name: "user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
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

  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
