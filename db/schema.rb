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

ActiveRecord::Schema.define(version: 20160409083316) do

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "items", force: :cascade do |t|
    t.integer  "user_id",             limit: 4,   null: false
    t.integer  "search_condition_id", limit: 4,   null: false
    t.string   "asin",                limit: 255, null: false
    t.string   "code",                limit: 255
    t.string   "name",                limit: 255
    t.integer  "is_prime",            limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "items", ["search_condition_id"], name: "index_items_on_search_condition_id", using: :btree
  add_index "items", ["user_id", "asin"], name: "index_items_on_user_id_and_asin", using: :btree

  create_table "labels", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,   null: false
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "labels", ["user_id"], name: "index_labels_on_user_id", using: :btree

  create_table "prohibited_words", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,   null: false
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prohibited_words", ["user_id"], name: "index_prohibited_words_on_user_id", using: :btree

  create_table "search_conditions", force: :cascade do |t|
    t.integer  "label_id",        limit: 4,               null: false
    t.string   "keyword",         limit: 255
    t.string   "negative_match",  limit: 255
    t.string   "category",        limit: 255,             null: false
    t.integer  "is_prime",        limit: 4,               null: false
    t.integer  "min_offer_count", limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_conditions", ["label_id"], name: "index_search_conditions_on_label_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "memo",                   limit: 255
    t.string   "aws_access_key_id",      limit: 255
    t.string   "aws_secret_key",         limit: 255
    t.string   "associate_tag",          limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
