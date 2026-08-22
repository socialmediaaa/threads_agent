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

ActiveRecord::Schema[8.1].define(version: 2026_08_21_164159) do
  create_table "audit_logs", force: :cascade do |t|
    t.string "action"
    t.string "actor"
    t.datetime "created_at", null: false
    t.json "details"
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_audit_logs_on_post_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "media_url"
    t.datetime "published_at"
    t.datetime "scheduled_at"
    t.integer "status", default: 0, null: false
    t.integer "thread_account_id", null: false
    t.string "threads_media_id"
    t.string "threads_post_id"
    t.datetime "updated_at", null: false
    t.index ["status", "scheduled_at"], name: "index_posts_on_status_and_scheduled_at"
    t.index ["thread_account_id"], name: "index_posts_on_thread_account_id"
  end

  create_table "thread_accounts", force: :cascade do |t|
    t.string "access_token", null: false
    t.datetime "created_at", null: false
    t.string "threads_user_id", null: false
    t.datetime "token_expires_at"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["threads_user_id"], name: "index_thread_accounts_on_threads_user_id", unique: true
  end

  add_foreign_key "audit_logs", "posts"
  add_foreign_key "posts", "thread_accounts"
end
