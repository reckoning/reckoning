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

ActiveRecord::Schema.define(version: 20170716193428) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "uuid-ossp"
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "accounts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.string "plan"
    t.hstore "settings"
    t.hstore "bank_account"
    t.hstore "services"
    t.hstore "mailing"
    t.hstore "contact_information"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "trail_end_at"
    t.boolean "trail_used"
    t.string "stripe_email"
    t.string "stripe_token"
    t.string "vat_id"
    t.boolean "feature_expenses", default: false
    t.boolean "feature_logbook", default: false
  end

  create_table "auth_tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "token"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "expires"
    t.index ["token"], name: "index_auth_tokens_on_token"
  end

  create_table "contacts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "customers", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "address_id"
    t.integer "payment_due"
    t.text "email_template"
    t.string "invoice_email", limit: 255
    t.string "default_from", limit: 255
    t.hstore "contact_information"
    t.string "name", limit: 255
    t.uuid "account_id", null: false
    t.date "employment_date"
    t.integer "weekly_hours"
  end

  create_table "expenses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "expense_type", null: false
    t.decimal "value", precision: 10, scale: 2, default: "0.0", null: false
    t.string "description"
    t.date "date", null: false
    t.uuid "account_id", null: false
    t.string "receipt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seller"
    t.integer "private_use_percent", default: 0, null: false
    t.decimal "usable_value", precision: 10, scale: 2, default: "0.0", null: false
    t.string "receipt_id"
    t.string "receipt_filename"
    t.integer "receipt_size"
    t.string "receipt_content_type"
    t.string "afa_type"
  end

  create_table "holidays", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.date "date"
    t.string "name_de"
    t.string "name_en"
    t.string "country_code"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoices", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.date "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal "value", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "rate", precision: 10, scale: 2, default: "0.0", null: false
    t.string "workflow_state", limit: 255
    t.datetime "pay_date"
    t.integer "ref"
    t.boolean "pdf_generating", default: false, null: false
    t.date "delivery_date"
    t.date "payment_due_date"
    t.datetime "pdf_generated_at"
    t.uuid "customer_id"
    t.uuid "project_id"
    t.uuid "account_id", null: false
  end

  create_table "plans", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "code"
    t.decimal "base_price"
    t.integer "quantity"
    t.string "interval"
    t.integer "discount"
    t.boolean "featured"
    t.string "stripe_plan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "positions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.decimal "hours", precision: 10, scale: 2
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal "value", precision: 10, scale: 2
    t.decimal "rate", precision: 10, scale: 2
    t.uuid "invoice_id"
  end

  create_table "projects", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal "rate", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "budget", precision: 10, scale: 2, default: "0.0", null: false
    t.uuid "customer_id"
    t.boolean "budget_on_dashboard", default: true
    t.string "workflow_state", default: "active", null: false
    t.decimal "budget_hours", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "round_up", default: "10.0", null: false
    t.datetime "start_date"
    t.datetime "end_date"
  end

  create_table "sick_days", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.date "date"
    t.uuid "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "states", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name_de"
    t.string "name_en"
    t.string "code"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid "project_id"
    t.boolean "billable", default: true, null: false
  end

  create_table "timers", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.date "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid "position_id"
    t.uuid "task_id"
    t.datetime "started_at"
    t.uuid "user_id", null: false
    t.text "note"
    t.decimal "value", precision: 30, scale: 18
    t.boolean "notified", default: false
  end

  create_table "tours", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.text "description"
    t.uuid "vessel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "distance", default: 0, null: false
    t.integer "duration", default: 0, null: false
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.integer "failed_attempts", default: 0
    t.string "unlock_token", limit: 255
    t.datetime "locked_at"
    t.string "authentication_token", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "address_id"
    t.boolean "enabled", default: false
    t.boolean "admin", default: false
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email", limit: 255
    t.string "gravatar", limit: 255
    t.string "gravatar_hash", limit: 255
    t.string "plan", limit: 255
    t.uuid "account_id", null: false
    t.string "name"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.boolean "otp_required_for_login"
    t.string "otp_backup_codes", array: true
    t.boolean "created_via_admin", default: false
    t.integer "consumed_timestep"
    t.string "layout", default: "top"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "vessels", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "manufacturer", null: false
    t.string "vessel_type", null: false
    t.decimal "buying_price", precision: 10, scale: 2, default: "0.0"
    t.date "buying_date", null: false
    t.integer "initial_milage", default: 0, null: false
    t.integer "milage", default: 0, null: false
    t.string "image_id"
    t.string "license_plate", null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "waypoints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "tour_id", null: false
    t.uuid "driver_id", null: false
    t.integer "milage", default: 0, null: false
    t.float "latitude"
    t.float "longitude"
    t.datetime "time", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location", null: false
    t.uuid "account_id", null: false
  end

end
