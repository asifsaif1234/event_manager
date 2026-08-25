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

ActiveRecord::Schema[8.1].define(version: 2026_08_25_094649) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "events", force: :cascade do |t|
    t.boolean "availability"
    t.string "branded_url"
    t.jsonb "categorization_data", default: {}
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_date"
    t.string "event_id", null: false
    t.jsonb "headliners_data", default: {}
    t.string "image_link"
    t.string "kind"
    t.datetime "last_synced_at"
    t.jsonb "location_data", default: {}
    t.string "object_type"
    t.jsonb "organiser_data", default: {}
    t.jsonb "organization_data", default: {}
    t.integer "price_amount_in_cents"
    t.string "price_currency"
    t.datetime "start_date"
    t.string "state", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index "((categorization_data ->> 'category'::text))", name: "index_events_on_category"
    t.index "((location_data ->> 'city'::text))", name: "index_events_on_city"
    t.index "((organiser_data ->> 'id'::text))", name: "index_events_on_organiser_id"
    t.index ["availability"], name: "index_events_on_availability"
    t.index ["event_id"], name: "index_events_on_event_id", unique: true
    t.index ["kind"], name: "index_events_on_kind"
    t.index ["start_date"], name: "index_events_on_start_date"
    t.index ["state"], name: "index_events_on_state"
    t.index ["title"], name: "index_events_on_title"
  end
end
