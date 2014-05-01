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

ActiveRecord::Schema.define(version: 20140501090806) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "addresses", force: true do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.string   "country"
    t.string   "email"
    t.string   "telefon"
    t.string   "fax"
    t.integer  "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "website"
    t.string   "company"
    t.string   "name"
    t.text     "address"
    t.text     "contact"
    t.string   "resource_type"
  end

  add_index "addresses", ["resource_id"], name: "index_addresses_on_resource_id", using: :btree

  create_table "customers", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "address_id"
    t.integer  "payment_due"
    t.integer  "user_id"
    t.text     "email_template"
    t.string   "invoice_email"
    t.string   "default_from"
  end

  create_table "invoices", force: true do |t|
    t.integer  "customer_id"
    t.integer  "project_id"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "value",            precision: 10, scale: 2, default: 0.0,   null: false
    t.decimal  "rate",             precision: 10, scale: 2, default: 0.0,   null: false
    t.string   "state"
    t.datetime "pay_date"
    t.integer  "ref"
    t.integer  "user_id"
    t.boolean  "pdf_generating",                            default: false, null: false
    t.date     "delivery_date"
    t.date     "payment_due_date"
    t.datetime "pdf_generated_at"
  end

  add_index "invoices", ["customer_id"], name: "index_invoices_on_customer_id", using: :btree
  add_index "invoices", ["project_id"], name: "index_invoices_on_project_id", using: :btree

  create_table "positions", force: true do |t|
    t.decimal  "hours",       precision: 10, scale: 2
    t.integer  "invoice_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "value",       precision: 10, scale: 2
    t.decimal  "rate",        precision: 10, scale: 2
  end

  add_index "positions", ["invoice_id"], name: "index_positions_on_invoice_id", using: :btree

  create_table "projects", force: true do |t|
    t.integer  "customer_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "rate",        precision: 10, scale: 2, default: 0.0, null: false
    t.decimal  "budget",      precision: 10, scale: 2, default: 0.0, null: false
  end

  add_index "projects", ["customer_id"], name: "index_projects_on_customer_id", using: :btree

  create_table "settings", force: true do |t|
    t.string   "keypath"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", force: true do |t|
    t.integer  "project_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "tasks", ["project_id"], name: "index_tasks_on_project_id", using: :btree

  create_table "tasks_weeks", id: false, force: true do |t|
    t.integer "task_id"
    t.integer "week_id"
  end

  add_index "tasks_weeks", ["task_id", "week_id"], name: "index_tasks_weeks_on_task_id_and_week_id", using: :btree
  add_index "tasks_weeks", ["week_id"], name: "index_tasks_weeks_on_week_id", using: :btree

  create_table "timers", force: true do |t|
    t.date     "date"
    t.string   "value"
    t.integer  "task_id"
    t.integer  "week_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position_id"
  end

  add_index "timers", ["position_id"], name: "index_timers_on_position_id", using: :btree
  add_index "timers", ["task_id"], name: "index_timers_on_task_id", using: :btree
  add_index "timers", ["week_id"], name: "index_timers_on_week_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",        default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore   "settings"
    t.hstore   "bank_account"
    t.integer  "address_id"
    t.boolean  "enabled",                default: false
    t.boolean  "admin",                  default: false
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "gravatar"
    t.string   "gravatar_hash"
    t.string   "plan"
    t.hstore   "services"
    t.hstore   "mailing"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["bank_account"], name: "users_gin_bank_account", using: :gin
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["settings"], name: "users_gin_settings", using: :gin
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  create_table "weeks", force: true do |t|
    t.date     "start_date"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "weeks", ["user_id"], name: "index_weeks_on_user_id", using: :btree

end
