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

ActiveRecord::Schema.define(version: 20151130114817) do

  create_table "items", force: true do |t|
    t.integer  "user_id",             null: false
    t.integer  "search_condition_id", null: false
    t.string   "asin",                null: false
    t.string   "code"
    t.string   "name"
    t.integer  "is_prime"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "items", ["search_condition_id"], name: "index_items_on_search_condition_id", using: :btree
  add_index "items", ["user_id", "asin"], name: "index_items_on_user_id_and_asin", using: :btree

  create_table "labels", force: true do |t|
    t.integer  "user_id",    null: false
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "labels", ["user_id"], name: "index_labels_on_user_id", using: :btree

  create_table "prohibited_words", force: true do |t|
    t.integer  "user_id",    null: false
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prohibited_words", ["user_id"], name: "index_prohibited_words_on_user_id", using: :btree

  create_table "search_conditions", force: true do |t|
    t.integer  "label_id",       null: false
    t.string   "keyword"
    t.string   "negative_match"
    t.string   "category",       null: false
    t.integer  "is_prime",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_conditions", ["label_id"], name: "index_search_conditions_on_label_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "memo"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
