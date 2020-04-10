# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_03_26_231510) do

  create_table "companies", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "domain"
    t.string "name"
    t.text "description"
    t.text "description2"
    t.text "description3"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "industry_tags"
    t.text "more_company_description"
    t.boolean "serves_traditional_market"
    t.float "revenue"
    t.integer "no_of_employees", default: 0
    t.string "headquarters"
    t.boolean "populated", default: false
    t.text "founder_blurb"
    t.text "key_people_blurb"
    t.boolean "has_valid_info", default: false
    t.string "funding_stage"
    t.string "phone"
    t.string "source"
    t.string "linkedin_link"
    t.string "funding_amount"
    t.string "acquired_by"
    t.boolean "is_consumer_centric", default: false
    t.string "email"
    t.string "source_url"
    t.string "company_type"
    t.string "ipo_status"
    t.boolean "is_our_customer", default: false
    t.string "email_pattern1"
    t.string "email_pattern2"
    t.index ["domain"], name: "index_companies_on_domain", unique: true
  end

  create_table "customer_prospects", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "customer_id"
    t.integer "prospect_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "has_been_contacted", default: false
    t.datetime "last_time_contacted"
  end

  create_table "key_people", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "email_address"
    t.string "first_name"
    t.string "last_name"
    t.string "title"
    t.integer "company_id"
    t.boolean "email_verified", default: false
    t.string "phone_number"
    t.integer "no_of_times_contacted", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "last_time_contacted"
    t.boolean "email_bounced", default: true
  end

end
