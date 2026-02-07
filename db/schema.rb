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

ActiveRecord::Schema[8.1].define(version: 2026_02_07_134717) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attachments", force: :cascade do |t|
    t.integer "attachable_id", null: false
    t.string "attachable_type", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.text "system_prompt"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_conversations_on_project_id"
    t.index ["updated_at"], name: "index_conversations_on_updated_at"
  end

  create_table "knowledge_bases", force: :cascade do |t|
    t.string "category"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.text "tags"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["project_id", "category"], name: "index_knowledge_bases_on_project_id_and_category"
    t.index ["project_id"], name: "index_knowledge_bases_on_project_id"
    t.index ["updated_at"], name: "index_knowledge_bases_on_updated_at"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
  end

  create_table "notes", force: :cascade do |t|
    t.string "category"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_notes_on_project_id"
    t.index ["updated_at"], name: "index_notes_on_updated_at"
  end

  create_table "projects", force: :cascade do |t|
    t.boolean "archived"
    t.string "color"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "scheduled_jobs", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "cron_expression"
    t.datetime "last_run_at"
    t.string "name"
    t.datetime "next_run_at"
    t.integer "project_id", null: false
    t.text "prompt_template"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["next_run_at"], name: "index_scheduled_jobs_on_next_run_at"
    t.index ["project_id", "active"], name: "index_scheduled_jobs_on_project_id_and_active"
    t.index ["project_id"], name: "index_scheduled_jobs_on_project_id"
    t.index ["status"], name: "index_scheduled_jobs_on_status"
  end

  create_table "todos", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "position"
    t.integer "priority"
    t.integer "project_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["project_id", "position"], name: "index_todos_on_project_id_and_position"
    t.index ["project_id", "status", "position"], name: "index_todos_on_project_id_and_status_and_position"
    t.index ["project_id", "status"], name: "index_todos_on_project_id_and_status"
    t.index ["project_id"], name: "index_todos_on_project_id"
    t.index ["updated_at"], name: "index_todos_on_updated_at"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "conversations", "projects"
  add_foreign_key "knowledge_bases", "projects"
  add_foreign_key "messages", "conversations"
  add_foreign_key "notes", "projects"
  add_foreign_key "scheduled_jobs", "projects"
  add_foreign_key "todos", "projects"
end
