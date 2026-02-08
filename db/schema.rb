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

ActiveRecord::Schema[8.1].define(version: 2026_02_08_170000) do
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
    t.boolean "archived", default: false, null: false
    t.datetime "archived_at"
    t.datetime "compacted_at"
    t.text "compacted_summary"
    t.integer "compacted_until_message_id"
    t.datetime "created_at", null: false
    t.string "pi_model"
    t.string "pi_provider"
    t.boolean "processing", default: false, null: false
    t.datetime "processing_started_at"
    t.integer "project_id", null: false
    t.integer "scheduled_job_id"
    t.text "system_prompt"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["archived"], name: "index_conversations_on_archived"
    t.index ["compacted_until_message_id"], name: "index_conversations_on_compacted_until_message_id"
    t.index ["pi_model"], name: "index_conversations_on_pi_model"
    t.index ["pi_provider"], name: "index_conversations_on_pi_provider"
    t.index ["project_id", "archived", "updated_at"], name: "index_conversations_on_project_id_and_archived_and_updated_at"
    t.index ["project_id"], name: "index_conversations_on_project_id"
    t.index ["scheduled_job_id"], name: "index_conversations_on_scheduled_job_id"
    t.index ["updated_at"], name: "index_conversations_on_updated_at"
  end

  create_table "heartbeat_events", force: :cascade do |t|
    t.text "agent_error"
    t.text "agent_message"
    t.string "agent_model"
    t.string "agent_provider"
    t.string "agent_status"
    t.text "alerts_json"
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.datetime "started_at", null: false
    t.string "status", null: false
    t.integer "stuck_conversations_fixed"
    t.integer "stuck_messages_fixed"
    t.integer "stuck_tool_calls_fixed"
    t.datetime "updated_at", null: false
    t.index ["started_at"], name: "index_heartbeat_events_on_started_at"
    t.index ["status"], name: "index_heartbeat_events_on_status"
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

  create_table "knowledge_searches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.datetime "finished_at"
    t.string "mode", null: false
    t.string "query", null: false
    t.json "results"
    t.datetime "started_at"
    t.string "status", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_knowledge_searches_on_created_at"
    t.index ["status"], name: "index_knowledge_searches_on_status"
  end

  create_table "message_tool_calls", force: :cascade do |t|
    t.json "args"
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.boolean "is_error", default: false, null: false
    t.integer "message_id", null: false
    t.text "output_text"
    t.datetime "started_at"
    t.string "status", default: "running", null: false
    t.string "tool_call_id", null: false
    t.string "tool_name", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "tool_call_id"], name: "index_message_tool_calls_on_message_id_and_tool_call_id", unique: true
    t.index ["message_id"], name: "index_message_tool_calls_on_message_id"
    t.index ["tool_call_id"], name: "index_message_tool_calls_on_tool_call_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.json "metadata"
    t.string "role", null: false
    t.string "status", default: "done", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["status"], name: "index_messages_on_status"
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

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.string "p256dh", null: false
    t.integer "project_id"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["project_id"], name: "index_push_subscriptions_on_project_id"
  end

  create_table "runtime_metrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_runtime_metrics_on_key", unique: true
  end

  create_table "scheduled_jobs", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "cron_expression"
    t.datetime "last_enqueued_at"
    t.datetime "last_run_at"
    t.string "name"
    t.datetime "next_run_at"
    t.string "pi_model"
    t.string "pi_provider"
    t.integer "project_id", null: false
    t.text "prompt_template"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["next_run_at"], name: "index_scheduled_jobs_on_next_run_at"
    t.index ["pi_model"], name: "index_scheduled_jobs_on_pi_model"
    t.index ["pi_provider"], name: "index_scheduled_jobs_on_pi_provider"
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
  add_foreign_key "conversations", "scheduled_jobs"
  add_foreign_key "knowledge_bases", "projects"
  add_foreign_key "message_tool_calls", "messages"
  add_foreign_key "messages", "conversations"
  add_foreign_key "notes", "projects"
  add_foreign_key "push_subscriptions", "projects"
  add_foreign_key "scheduled_jobs", "projects"
  add_foreign_key "todos", "projects"
end
