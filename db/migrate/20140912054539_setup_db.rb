class SetupDb < ActiveRecord::Migration
  def change
    enable_extension "plpgsql"
    enable_extension "hstore"
    enable_extension "uuid-ossp"

    create_table "customers", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "address_id"
      t.integer  "payment_due"
      t.text     "email_template"
      t.string   "invoice_email"
      t.string   "default_from"
      t.uuid     "user_id"
      t.hstore   "contact_information"
    end

    create_table "invoices", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.date     "date"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.decimal  "value",            precision: 10, scale: 2, default: 0.0,   null: false
      t.decimal  "rate",             precision: 10, scale: 2, default: 0.0,   null: false
      t.string   "state"
      t.datetime "pay_date"
      t.integer  "ref"
      t.boolean  "pdf_generating",                            default: false, null: false
      t.date     "delivery_date"
      t.date     "payment_due_date"
      t.datetime "pdf_generated_at"
      t.uuid     "user_id"
      t.uuid     "customer_id"
      t.uuid     "project_id"
    end

    create_table "positions", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.decimal  "hours",       precision: 10, scale: 2
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.decimal  "value",       precision: 10, scale: 2
      t.decimal  "rate",        precision: 10, scale: 2
      t.uuid     "invoice_id"
    end

    create_table "projects", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.decimal  "rate",        precision: 10, scale: 2, default: 0.0, null: false
      t.decimal  "budget",      precision: 10, scale: 2, default: 0.0, null: false
      t.uuid     "customer_id"
    end

    create_table "tasks", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.uuid     "project_id"
    end

    create_table "tasks_weeks", id: false, force: true do |t|
      t.uuid "week_id"
      t.uuid "task_id"
    end

    add_index "tasks_weeks", ["task_id", "week_id"], name: "index_tasks_weeks_on_task_id_and_week_id", using: :btree
    add_index "tasks_weeks", ["week_id"], name: "index_tasks_weeks_on_week_id", using: :btree

    create_table "timers", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.date     "date"
      t.string   "value"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.uuid     "position_id"
      t.uuid     "task_id"
      t.uuid     "week_id"
    end

    create_table "users", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
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
      t.hstore   "contact_information"
    end

    add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
    add_index "users", ["bank_account"], name: "users_gin_bank_account", using: :gin
    add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
    add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
    add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    add_index "users", ["settings"], name: "users_gin_settings", using: :gin
    add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

    create_table "weeks", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.date     "start_date"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.uuid     "user_id"
    end
  end
end
