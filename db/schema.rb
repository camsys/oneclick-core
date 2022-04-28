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

ActiveRecord::Schema.define(version: 20220424222311) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "pg_stat_statements"

  create_table "accommodations", force: :cascade do |t|
    t.string   "code",                     null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "rank",       default: 100, null: false
    t.index ["code"], name: "index_accommodations_on_code", unique: true, using: :btree
  end

  create_table "accommodations_services", id: false, force: :cascade do |t|
    t.integer "service_id",       null: false
    t.integer "accommodation_id", null: false
    t.index ["accommodation_id"], name: "index_accommodations_services_on_accommodation_id", using: :btree
    t.index ["service_id"], name: "index_accommodations_services_on_service_id", using: :btree
  end

  create_table "accommodations_trips", id: false, force: :cascade do |t|
    t.integer "trip_id",          null: false
    t.integer "accommodation_id", null: false
    t.index ["trip_id", "accommodation_id"], name: "index_accommodations_trips_on_trip_id_and_accommodation_id", using: :btree
  end

  create_table "accommodations_users", id: false, force: :cascade do |t|
    t.integer "user_id",          null: false
    t.integer "accommodation_id", null: false
    t.index ["accommodation_id"], name: "index_accommodations_users_on_accommodation_id", using: :btree
    t.index ["user_id"], name: "index_accommodations_users_on_user_id", using: :btree
  end

  create_table "agencies", force: :cascade do |t|
    t.string   "type"
    t.string   "name"
    t.string   "phone"
    t.string   "email"
    t.string   "url"
    t.string   "logo"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "published",      default: false
    t.integer  "agency_type_id"
    t.index ["agency_type_id"], name: "index_agencies_on_agency_type_id", using: :btree
    t.index ["published"], name: "index_agencies_on_published", using: :btree
  end

  create_table "agency_oversight_agencies", force: :cascade do |t|
    t.integer "transportation_agency_id"
    t.integer "oversight_agency_id"
    t.index ["oversight_agency_id"], name: "index_agency_oversight_agencies_on_oversight_agency_id", using: :btree
    t.index ["transportation_agency_id"], name: "index_agency_oversight_agencies_on_transportation_agency_id", using: :btree
  end

  create_table "agency_types", force: :cascade do |t|
    t.string "name"
  end

  create_table "alerts", force: :cascade do |t|
    t.datetime "expiration"
    t.string   "audience",         default: "everyone", null: false
    t.boolean  "published",        default: true,       null: false
    t.text     "audience_details"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "bookings", force: :cascade do |t|
    t.integer  "itinerary_id"
    t.string   "type"
    t.string   "status"
    t.string   "confirmation"
    t.text     "details"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.datetime "earliest_pu"
    t.datetime "latest_pu"
    t.datetime "negotiated_pu"
    t.datetime "negotiated_do"
    t.datetime "estimated_pu"
    t.datetime "estimated_do"
    t.boolean  "created_in_1click", default: false
    t.index ["itinerary_id"], name: "index_bookings_on_itinerary_id", using: :btree
  end

  create_table "cities", force: :cascade do |t|
    t.string   "name"
    t.string   "state"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.geometry "geom",       limit: {:srid=>4326, :type=>"geometry"}
    t.index ["name", "state"], name: "index_cities_on_name_and_state", using: :btree
  end

  create_table "comments", force: :cascade do |t|
    t.text     "comment"
    t.string   "locale"
    t.string   "commentable_type"
    t.integer  "commentable_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "commenter_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id", using: :btree
    t.index ["commenter_id"], name: "index_comments_on_commenter_id", using: :btree
  end

  create_table "configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "key"
    t.text     "value"
  end

  create_table "counties", force: :cascade do |t|
    t.string   "name"
    t.string   "state"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.geometry "geom",       limit: {:srid=>4326, :type=>"geometry"}
    t.index ["name", "state"], name: "index_counties_on_name_and_state", using: :btree
  end

  create_table "custom_geographies", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.geometry "geom",        limit: {:srid=>4326, :type=>"geometry"}
    t.integer  "agency_id"
    t.text     "description"
    t.index ["agency_id"], name: "index_custom_geographies_on_agency_id", using: :btree
    t.index ["name"], name: "index_custom_geographies_on_name", using: :btree
  end

  create_table "eligibilities", force: :cascade do |t|
    t.string   "code",                     null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "rank",       default: 100, null: false
    t.index ["code"], name: "index_eligibilities_on_code", unique: true, using: :btree
  end

  create_table "eligibilities_services", id: false, force: :cascade do |t|
    t.integer "service_id",     null: false
    t.integer "eligibility_id", null: false
    t.index ["eligibility_id"], name: "index_eligibilities_services_on_eligibility_id", using: :btree
    t.index ["service_id"], name: "index_eligibilities_services_on_service_id", using: :btree
  end

  create_table "eligibilities_trips", id: false, force: :cascade do |t|
    t.integer "trip_id",        null: false
    t.integer "eligibility_id", null: false
    t.index ["trip_id", "eligibility_id"], name: "index_eligibilities_trips_on_trip_id_and_eligibility_id", using: :btree
  end

  create_table "fare_zones", force: :cascade do |t|
    t.integer  "service_id"
    t.integer  "region_id"
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id", "region_id"], name: "index_fare_zones_on_service_id_and_region_id", using: :btree
  end

  create_table "feedbacks", force: :cascade do |t|
    t.string   "feedbackable_type"
    t.integer  "feedbackable_id"
    t.integer  "user_id"
    t.integer  "rating"
    t.text     "review"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.boolean  "acknowledged",      default: false
    t.string   "email"
    t.string   "phone"
    t.index ["feedbackable_type", "feedbackable_id"], name: "index_feedbacks_on_feedbackable_type_and_feedbackable_id", using: :btree
    t.index ["user_id"], name: "index_feedbacks_on_user_id", using: :btree
  end

  create_table "itineraries", force: :cascade do |t|
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "trip_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "legs"
    t.integer  "walk_time"
    t.integer  "transit_time"
    t.float    "cost"
    t.integer  "service_id"
    t.string   "trip_type"
    t.float    "walk_distance"
    t.integer  "wait_time"
    t.index ["service_id"], name: "index_itineraries_on_service_id", using: :btree
    t.index ["trip_id"], name: "index_itineraries_on_trip_id", using: :btree
  end

  create_table "landmark_sets", force: :cascade do |t|
    t.string  "name",        null: false
    t.integer "agency_id"
    t.text    "description"
    t.index ["agency_id"], name: "index_landmark_sets_on_agency_id", using: :btree
  end

  create_table "landmarks", force: :cascade do |t|
    t.datetime "created_at",                                                                      null: false
    t.datetime "updated_at",                                                                      null: false
    t.string   "name"
    t.string   "street_number"
    t.string   "route"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.boolean  "old"
    t.decimal  "lat",                                                    precision: 10, scale: 6
    t.decimal  "lng",                                                    precision: 10, scale: 6
    t.geometry "geom",          limit: {:srid=>4326, :type=>"st_point"}
    t.string   "county"
    t.integer  "agency_id"
    t.index ["agency_id"], name: "index_landmarks_on_agency_id", using: :btree
    t.index ["geom"], name: "index_landmarks_on_geom", using: :gist
    t.index ["name"], name: "idx_landmarks_on_name", using: :btree
  end

  create_table "locales", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lyft_extensions", force: :cascade do |t|
    t.string   "price_quote_id"
    t.integer  "itinerary_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["itinerary_id"], name: "index_lyft_extensions_on_itinerary_id", using: :btree
  end

  create_table "oneclick_refernet_categories", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "confirmed",    default: false
    t.integer  "sequence_nbr"
    t.string   "code"
    t.index ["name"], name: "index_oneclick_refernet_categories_on_name", using: :btree
  end

  create_table "oneclick_refernet_services", force: :cascade do |t|
    t.datetime  "created_at",                                                                                          null: false
    t.datetime  "updated_at",                                                                                          null: false
    t.boolean   "confirmed",                                                                           default: false
    t.text      "details"
    t.geometry  "latlng",                  limit: {:srid=>4326, :type=>"st_point"}
    t.string    "agency_name"
    t.string    "site_name"
    t.text      "description"
    t.geography "latlngg",                 limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.integer   "refernet_service_id"
    t.integer   "refernet_location_id"
    t.integer   "refernet_servicesite_id"
    t.index ["latlng"], name: "index_oneclick_refernet_services_on_latlng", using: :gist
    t.index ["latlngg"], name: "index_oneclick_refernet_services_on_latlngg", using: :gist
  end

  create_table "oneclick_refernet_services_sub_sub_categories", force: :cascade do |t|
    t.integer  "service_id"
    t.integer  "sub_sub_category_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["service_id"], name: "idx_svcs_cat_join_table_on_service_id", using: :btree
    t.index ["sub_sub_category_id"], name: "idx_svcs_cat_join_table_on_sub_sub_category_id", using: :btree
  end

  create_table "oneclick_refernet_sub_categories", force: :cascade do |t|
    t.string   "name"
    t.integer  "category_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "confirmed",            default: false
    t.integer  "refernet_category_id"
    t.string   "code"
    t.index ["category_id"], name: "index_oneclick_refernet_sub_categories_on_category_id", using: :btree
    t.index ["name"], name: "index_oneclick_refernet_sub_categories_on_name", using: :btree
  end

  create_table "oneclick_refernet_sub_sub_categories", force: :cascade do |t|
    t.string   "name"
    t.integer  "sub_category_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "confirmed",       default: false
    t.string   "code"
    t.index ["name"], name: "index_oneclick_refernet_sub_sub_categories_on_name", using: :btree
    t.index ["sub_category_id"], name: "index_oneclick_refernet_sub_sub_categories_on_sub_category_id", using: :btree
  end

  create_table "oneclick_refernet_translations", force: :cascade do |t|
    t.string   "key"
    t.string   "locale"
    t.text     "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_oneclick_refernet_translations_on_key", using: :btree
  end

  create_table "purposes", force: :cascade do |t|
    t.string   "code"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name",        null: false
    t.string   "description"
    t.integer  "agency_id"
    t.index ["agency_id"], name: "index_purposes_on_agency_id", using: :btree
  end

  create_table "purposes_services", id: false, force: :cascade do |t|
    t.integer "service_id", null: false
    t.integer "purpose_id", null: false
    t.index ["purpose_id"], name: "index_purposes_services_on_purpose_id", using: :btree
    t.index ["service_id"], name: "index_purposes_services_on_service_id", using: :btree
  end

  create_table "regions", force: :cascade do |t|
    t.text     "recipe"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.geometry "geom",       limit: {:srid=>4326, :type=>"multi_polygon"}
  end

  create_table "request_logs", force: :cascade do |t|
    t.string   "controller"
    t.string   "action"
    t.string   "status_code"
    t.text     "params"
    t.string   "auth_email"
    t.integer  "duration"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["controller", "action"], name: "index_request_logs_on_controller_and_action", using: :btree
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

  create_table "schedules", force: :cascade do |t|
    t.integer  "service_id"
    t.integer  "day"
    t.integer  "start_time"
    t.integer  "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day"], name: "index_schedules_on_day", using: :btree
    t.index ["service_id"], name: "index_schedules_on_service_id", using: :btree
  end

  create_table "service_oversight_agencies", force: :cascade do |t|
    t.integer "service_id"
    t.integer "oversight_agency_id"
    t.index ["oversight_agency_id"], name: "index_service_oversight_agencies_on_oversight_agency_id", using: :btree
    t.index ["service_id"], name: "index_service_oversight_agencies_on_service_id", using: :btree
  end

  create_table "service_schedule_types", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "service_schedules", force: :cascade do |t|
    t.integer  "service_schedule_type_id"
    t.string   "name"
    t.string   "description"
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "agency_id"
    t.index ["agency_id"], name: "index_service_schedules_on_agency_id", using: :btree
    t.index ["service_schedule_type_id"], name: "idx_service_schedules_to_service_schedule_types", using: :btree
  end

  create_table "service_sub_schedules", force: :cascade do |t|
    t.integer  "service_schedule_id"
    t.integer  "day"
    t.integer  "start_time"
    t.integer  "end_time"
    t.date     "calendar_date"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["service_schedule_id"], name: "idx_service_sub_schedules_to_service_schedules", using: :btree
  end

  create_table "services", force: :cascade do |t|
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "type"
    t.string   "name"
    t.string   "gtfs_agency_id"
    t.string   "logo"
    t.string   "email"
    t.string   "url"
    t.string   "phone"
    t.integer  "start_or_end_area_id"
    t.integer  "trip_within_area_id"
    t.string   "fare_structure"
    t.text     "fare_details"
    t.boolean  "archived",             default: false
    t.boolean  "published",            default: false
    t.integer  "agency_id"
    t.string   "booking_api"
    t.text     "booking_details"
    t.integer  "max_age",              default: 200,   null: false
    t.integer  "min_age",              default: 0,     null: false
    t.index ["agency_id"], name: "index_services_on_agency_id", using: :btree
    t.index ["archived"], name: "index_services_on_archived", using: :btree
    t.index ["gtfs_agency_id"], name: "index_services_on_gtfs_agency_id", using: :btree
    t.index ["name"], name: "index_services_on_name", using: :btree
    t.index ["published"], name: "index_services_on_published", using: :btree
    t.index ["start_or_end_area_id"], name: "index_services_on_start_or_end_area_id", using: :btree
    t.index ["trip_within_area_id"], name: "index_services_on_trip_within_area_id", using: :btree
  end

  create_table "stomping_grounds", force: :cascade do |t|
    t.string   "name"
    t.string   "street_number"
    t.string   "route"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.boolean  "old"
    t.decimal  "lat",                                                    precision: 10, scale: 6
    t.decimal  "lng",                                                    precision: 10, scale: 6
    t.geometry "geom",          limit: {:srid=>4326, :type=>"st_point"}
    t.datetime "created_at",                                                                      null: false
    t.datetime "updated_at",                                                                      null: false
    t.integer  "user_id"
    t.string   "county"
    t.index ["geom"], name: "index_stomping_grounds_on_geom", using: :gist
    t.index ["user_id"], name: "index_stomping_grounds_on_user_id", using: :btree
  end

  create_table "translation_keys", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "translations", force: :cascade do |t|
    t.integer  "locale_id"
    t.integer  "translation_key_id"
    t.text     "value"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "travel_pattern_service_schedules", force: :cascade do |t|
    t.integer  "travel_pattern_id"
    t.integer  "service_schedule_id"
    t.integer  "priority"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["service_schedule_id"], name: "index_travel_pattern_service_schedules_on_service_schedule_id", using: :btree
    t.index ["travel_pattern_id"], name: "index_travel_pattern_service_schedules_on_travel_pattern_id", using: :btree
  end

  create_table "travel_patterns", force: :cascade do |t|
    t.string  "name",        null: false
    t.text    "description"
    t.integer "agency_id"
    t.index ["agency_id"], name: "index_travel_patterns_on_agency_id", using: :btree
  end

  create_table "traveler_transit_agencies", force: :cascade do |t|
    t.integer "user_id"
    t.integer "transportation_agency_id"
    t.index ["transportation_agency_id"], name: "index_traveler_transit_agencies_on_transportation_agency_id", using: :btree
    t.index ["user_id"], name: "index_traveler_transit_agencies_on_user_id", using: :btree
  end

  create_table "trip_accommodations", force: :cascade do |t|
    t.integer "trip_id",          null: false
    t.integer "accommodation_id", null: false
    t.index ["accommodation_id"], name: "index_trip_accommodations_on_accommodation_id", using: :btree
    t.index ["trip_id"], name: "index_trip_accommodations_on_trip_id", using: :btree
  end

  create_table "trip_eligibilities", force: :cascade do |t|
    t.integer "trip_id",        null: false
    t.integer "eligibility_id", null: false
    t.index ["eligibility_id"], name: "index_trip_eligibilities_on_eligibility_id", using: :btree
    t.index ["trip_id"], name: "index_trip_eligibilities_on_trip_id", using: :btree
  end

  create_table "trip_purposes", force: :cascade do |t|
    t.integer "trip_id",    null: false
    t.integer "purpose_id", null: false
    t.index ["purpose_id"], name: "index_trip_purposes_on_purpose_id", using: :btree
    t.index ["trip_id"], name: "index_trip_purposes_on_trip_id", using: :btree
  end

  create_table "trips", force: :cascade do |t|
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.integer  "user_id"
    t.integer  "origin_id"
    t.integer  "destination_id"
    t.datetime "trip_time"
    t.boolean  "arrive_by",             default: false
    t.integer  "selected_itinerary_id"
    t.integer  "purpose_id"
    t.integer  "previous_trip_id"
    t.string   "external_purpose"
    t.text     "details"
    t.string   "disposition_status",    default: "Unknown Disposition"
    t.index ["destination_id"], name: "index_trips_on_destination_id", using: :btree
    t.index ["origin_id"], name: "index_trips_on_origin_id", using: :btree
    t.index ["previous_trip_id"], name: "index_trips_on_previous_trip_id", using: :btree
    t.index ["purpose_id"], name: "index_trips_on_purpose_id", using: :btree
    t.index ["selected_itinerary_id"], name: "index_trips_on_selected_itinerary_id", using: :btree
    t.index ["user_id"], name: "index_trips_on_user_id", using: :btree
  end

  create_table "uber_extensions", force: :cascade do |t|
    t.string   "product_id"
    t.integer  "itinerary_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["itinerary_id"], name: "index_uber_extensions_on_itinerary_id", using: :btree
  end

  create_table "user_alerts", force: :cascade do |t|
    t.boolean  "acknowledged", default: false, null: false
    t.integer  "alert_id",                     null: false
    t.integer  "user_id",                      null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "user_booking_profiles", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "service_id"
    t.string   "booking_api"
    t.text     "details"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "encrypted_external_password"
    t.string   "encrypted_external_password_iv"
    t.string   "external_user_id"
    t.index ["external_user_id"], name: "index_user_booking_profiles_on_external_user_id", using: :btree
    t.index ["service_id"], name: "index_user_booking_profiles_on_service_id", using: :btree
    t.index ["user_id"], name: "index_user_booking_profiles_on_user_id", using: :btree
  end

  create_table "user_eligibilities", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "eligibility_id"
    t.boolean  "value",          default: true
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["eligibility_id"], name: "index_user_eligibilities_on_eligibility_id", using: :btree
    t.index ["user_id"], name: "index_user_eligibilities_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "email",                             default: "",   null: false
    t.string   "encrypted_password",                default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                     default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "authentication_token",   limit: 30
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "preferred_locale_id"
    t.text     "preferred_trip_types"
    t.integer  "failed_attempts",                   default: 0,    null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean  "subscribed_to_emails",              default: true
    t.integer  "age"
    t.integer  "current_agency_id"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
    t.index ["current_agency_id"], name: "index_users_on_current_agency_id", using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["last_name", "first_name"], name: "index_users_on_last_name_and_first_name", using: :btree
    t.index ["preferred_locale_id"], name: "index_users_on_preferred_locale_id", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree
  end

  create_table "waypoints", force: :cascade do |t|
    t.datetime "created_at",                                                                      null: false
    t.datetime "updated_at",                                                                      null: false
    t.string   "name"
    t.string   "street_number"
    t.string   "route"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.decimal  "lat",                                                    precision: 10, scale: 6
    t.decimal  "lng",                                                    precision: 10, scale: 6
    t.geometry "geom",          limit: {:srid=>4326, :type=>"st_point"}
    t.string   "county"
    t.index ["geom"], name: "index_waypoints_on_geom", using: :gist
  end

  create_table "zipcodes", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.geometry "geom",       limit: {:srid=>4326, :type=>"geometry"}
    t.index ["name"], name: "index_zipcodes_on_name", using: :btree
  end

  add_foreign_key "agencies", "agency_types"
  add_foreign_key "agency_oversight_agencies", "agencies", column: "oversight_agency_id", on_delete: :cascade
  add_foreign_key "agency_oversight_agencies", "agencies", column: "transportation_agency_id", on_delete: :cascade
  add_foreign_key "bookings", "itineraries"
  add_foreign_key "comments", "users", column: "commenter_id"
  add_foreign_key "custom_geographies", "agencies"
  add_foreign_key "itineraries", "services"
  add_foreign_key "itineraries", "trips"
  add_foreign_key "landmark_sets", "agencies"
  add_foreign_key "landmarks", "agencies"
  add_foreign_key "oneclick_refernet_services_sub_sub_categories", "oneclick_refernet_services", column: "service_id"
  add_foreign_key "oneclick_refernet_services_sub_sub_categories", "oneclick_refernet_sub_sub_categories", column: "sub_sub_category_id"
  add_foreign_key "oneclick_refernet_sub_categories", "oneclick_refernet_categories", column: "category_id"
  add_foreign_key "oneclick_refernet_sub_sub_categories", "oneclick_refernet_sub_categories", column: "sub_category_id"
  add_foreign_key "purposes", "agencies"
  add_foreign_key "schedules", "services"
  add_foreign_key "service_oversight_agencies", "agencies", column: "oversight_agency_id", on_delete: :cascade
  add_foreign_key "service_oversight_agencies", "services", on_delete: :cascade
  add_foreign_key "services", "agencies"
  add_foreign_key "services", "regions", column: "start_or_end_area_id"
  add_foreign_key "services", "regions", column: "trip_within_area_id"
  add_foreign_key "stomping_grounds", "users"
  add_foreign_key "traveler_transit_agencies", "agencies", column: "transportation_agency_id", on_delete: :cascade
  add_foreign_key "traveler_transit_agencies", "users", on_delete: :cascade
  add_foreign_key "trips", "itineraries", column: "selected_itinerary_id"
  add_foreign_key "trips", "purposes"
  add_foreign_key "trips", "trips", column: "previous_trip_id"
  add_foreign_key "trips", "users"
  add_foreign_key "trips", "waypoints", column: "destination_id"
  add_foreign_key "trips", "waypoints", column: "origin_id"
  add_foreign_key "user_booking_profiles", "services"
  add_foreign_key "user_booking_profiles", "users"
  add_foreign_key "user_eligibilities", "eligibilities"
  add_foreign_key "user_eligibilities", "users"
  add_foreign_key "users", "agencies", column: "current_agency_id"
  add_foreign_key "users", "locales", column: "preferred_locale_id"
end
