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

ActiveRecord::Schema.define(version: 20170224214520) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accommodations", force: :cascade do |t|
    t.string   "code",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "key"
    t.text     "value"
  end

  create_table "eligibilities", force: :cascade do |t|
    t.string   "code",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "itineraries", force: :cascade do |t|
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "trip_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "legs"
    t.integer  "walk_time"
    t.integer  "transit_time"
    t.float    "cost"
    t.integer  "service_id"
    t.index ["service_id"], name: "index_itineraries_on_service_id", using: :btree
    t.index ["trip_id"], name: "index_itineraries_on_trip_id", using: :btree
  end

  create_table "landmarks", force: :cascade do |t|
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "name"
    t.string   "street_number"
    t.string   "route"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.boolean  "old"
    t.decimal  "lat",           precision: 10, scale: 6
    t.decimal  "lng",           precision: 10, scale: 6
  end

  create_table "purposes", force: :cascade do |t|
    t.string   "code",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
    t.index ["name"], name: "index_roles_on_name", using: :btree
  end

  create_table "services", force: :cascade do |t|
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "type"
    t.string   "name"
    t.string   "gtfs_agency_id"
    t.string   "logo"
    t.string   "email"
    t.string   "url"
    t.string   "phone"
    t.index ["gtfs_agency_id"], name: "index_services_on_gtfs_agency_id", using: :btree
    t.index ["name"], name: "index_services_on_name", using: :btree
  end

  create_table "trips", force: :cascade do |t|
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "user_id"
    t.integer  "origin_id"
    t.integer  "destination_id"
    t.datetime "trip_time"
    t.boolean  "arrive_by"
    t.index ["destination_id"], name: "index_trips_on_destination_id", using: :btree
    t.index ["origin_id"], name: "index_trips_on_origin_id", using: :btree
    t.index ["user_id"], name: "index_trips_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.string   "email",                             default: "", null: false
    t.string   "encrypted_password",                default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                     default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "authentication_token",   limit: 30
    t.string   "first_name"
    t.string   "last_name"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["last_name", "first_name"], name: "index_users_on_last_name_and_first_name", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree
  end

  create_table "waypoints", force: :cascade do |t|
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "name"
    t.string   "street_number"
    t.string   "route"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.decimal  "lat",           precision: 10, scale: 6
    t.decimal  "lng",           precision: 10, scale: 6
  end

  add_foreign_key "itineraries", "services"
  add_foreign_key "itineraries", "trips"
  add_foreign_key "trips", "users"
  add_foreign_key "trips", "waypoints", column: "destination_id"
  add_foreign_key "trips", "waypoints", column: "origin_id"
end
