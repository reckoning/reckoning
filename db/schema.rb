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

ActiveRecord::Schema[7.0].define(version: 2023_09_24_131008) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.string "plan"
    t.hstore "settings"
    t.hstore "bank_account"
    t.hstore "services"
    t.hstore "mailing"
    t.hstore "contact_information"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "trail_end_at", precision: nil
    t.boolean "trail_used"
    t.string "stripe_email"
    t.string "stripe_token"
    t.string "vat_id"
    t.boolean "feature_expenses", default: false
    t.boolean "feature_logbook", default: false
    t.integer "office_space"
    t.integer "deductible_office_space"
    t.integer "deductible_office_percent"
    t.text "offer_headline"
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "afa_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "value", null: false
    t.date "valid_from", null: false
    t.date "valid_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "key"
  end

  create_table "auth_tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "token"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "user_agent"
    t.integer "expires"
    t.index ["token", "user_id"], name: "index_auth_tokens_on_token_and_user_id", unique: true
    t.index ["token"], name: "index_auth_tokens_on_token"
  end

  create_table "customers", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
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
    t.date "employment_end_date"
    t.text "offer_disclaimer"
    t.string "invoice_email_cc"
    t.string "invoice_email_bcc"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "expenses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "expense_type", null: false
    t.decimal "value", precision: 10, scale: 2, default: "0.0", null: false
    t.string "description"
    t.date "date"
    t.uuid "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "seller"
    t.integer "private_use_percent", default: 0, null: false
    t.integer "afa_type_old"
    t.integer "vat_percent", default: 0, null: false
    t.date "started_at"
    t.date "ended_at"
    t.integer "interval", default: 0, null: false
    t.uuid "afa_type_id"
  end

  create_table "invoices", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.date "date"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "value", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "rate", precision: 10, scale: 2, default: "0.0", null: false
    t.string "workflow_state", limit: 255
    t.datetime "pay_date", precision: nil
    t.integer "ref"
    t.boolean "pdf_generating", default: false, null: false
    t.date "delivery_date"
    t.date "payment_due_date"
    t.datetime "pdf_generated_at", precision: nil
    t.uuid "customer_id"
    t.uuid "project_id"
    t.uuid "account_id", null: false
    t.index ["ref", "account_id"], name: "index_invoices_on_ref_and_account_id", unique: true
  end

  create_table "mobility_string_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.string "value"
    t.string "translatable_type"
    t.uuid "translatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "index_mobility_string_translations_on_translatable_attribute"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "index_mobility_string_translations_on_keys", unique: true
    t.index ["translatable_type", "key", "value", "locale"], name: "index_mobility_string_translations_on_query_keys"
  end

  create_table "mobility_text_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.text "value"
    t.string "translatable_type"
    t.uuid "translatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "index_mobility_text_translations_on_translatable_attribute"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "index_mobility_text_translations_on_keys", unique: true
  end

  create_table "offers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "customer_id"
    t.uuid "project_id"
    t.text "description"
    t.date "date"
    t.decimal "value", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "rate", precision: 10, scale: 2, default: "0.0", null: false
    t.string "aasm_state"
    t.integer "ref"
    t.boolean "pdf_generating", default: false, null: false
    t.datetime "pdf_generated_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ref", "account_id"], name: "index_offers_on_ref_and_account_id", unique: true
  end

  create_table "plans", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "code"
    t.decimal "base_price"
    t.integer "quantity"
    t.string "interval"
    t.integer "discount"
    t.boolean "featured"
    t.string "stripe_plan_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "positions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.decimal "hours", precision: 10, scale: 2
    t.text "description"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "value", precision: 10, scale: 2
    t.decimal "rate", precision: 10, scale: 2
    t.uuid "invoice_id"
    t.string "type"
    t.uuid "invoicable_id"
    t.string "invoicable_type"
  end

  create_table "projects", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "rate", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "budget", precision: 10, scale: 2, default: "0.0", null: false
    t.uuid "customer_id"
    t.boolean "budget_on_dashboard", default: true
    t.string "workflow_state", default: "active", null: false
    t.decimal "budget_hours", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "round_up", default: "10.0", null: false
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.text "invoice_addition"
  end

  create_table "tasks", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "project_id"
    t.boolean "billable", default: true, null: false
  end

  create_table "tax_rates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id"
    t.decimal "value", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "valid_from", precision: nil, null: false
    t.datetime "valid_until", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "timers", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.date "date"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "position_id"
    t.uuid "task_id"
    t.datetime "started_at", precision: nil
    t.uuid "user_id", null: false
    t.text "note"
    t.decimal "value", precision: 30, scale: 18
    t.boolean "notified", default: false
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.integer "failed_attempts", default: 0
    t.string "unlock_token", limit: 255
    t.datetime "locked_at", precision: nil
    t.string "authentication_token", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "address_id"
    t.boolean "enabled", default: false
    t.boolean "admin", default: false
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
