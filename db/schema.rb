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

ActiveRecord::Schema[8.1].define(version: 2026_05_12_193936) do
  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bank_transactions", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.string "description"
    t.string "holded_ref", null: false
    t.integer "matched_filing_id"
    t.date "posted_on", null: false
    t.datetime "updated_at", null: false
    t.index ["holded_ref"], name: "index_bank_transactions_on_holded_ref", unique: true
    t.index ["matched_filing_id"], name: "index_bank_transactions_on_matched_filing_id"
    t.index ["posted_on"], name: "index_bank_transactions_on_posted_on"
  end

  create_table "filings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "filable_id", null: false
    t.string "filable_type", null: false
    t.datetime "filed_at"
    t.string "folder", null: false
    t.string "holded_ref"
    t.text "note"
    t.integer "period_month"
    t.integer "period_quarter"
    t.integer "period_year", null: false
    t.datetime "received_at", null: false
    t.string "source", null: false
    t.string "status", default: "pending", null: false
    t.datetime "trashed_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["filable_type", "filable_id"], name: "idx_filings_on_filable_unique", unique: true
    t.index ["filable_type", "filable_id"], name: "index_filings_on_filable"
    t.index ["folder", "period_year", "period_month"], name: "index_filings_on_folder_and_period_year_and_period_month"
    t.index ["holded_ref"], name: "index_filings_on_holded_ref", unique: true, where: "holded_ref IS NOT NULL"
    t.index ["trashed_at"], name: "index_filings_on_trashed_at"
    t.index ["user_id", "status"], name: "index_filings_on_user_id_and_status"
    t.index ["user_id"], name: "index_filings_on_user_id"
  end

  create_table "issued_invoice_line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "issued_invoice_id", null: false
    t.integer "position", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.integer "unit_amount_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["issued_invoice_id", "position"], name: "idx_invoice_line_items_position_unique", unique: true
    t.index ["issued_invoice_id"], name: "index_issued_invoice_line_items_on_issued_invoice_id"
  end

  create_table "issued_invoices", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.string "client_name", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.string "invoice_status", default: "draft", null: false
    t.date "issued_on"
    t.string "number", null: false
    t.integer "period_month", null: false
    t.integer "period_year", null: false
    t.datetime "updated_at", null: false
    t.string "verifactu_ref"
    t.index ["number"], name: "index_issued_invoices_on_number", unique: true
    t.index ["period_year", "period_month"], name: "index_issued_invoices_on_period_year_and_period_month"
  end

  create_table "operations", force: :cascade do |t|
    t.string "adapter_name", null: false
    t.integer "attempt_count", default: 0, null: false
    t.datetime "completed_at"
    t.string "correlation_id"
    t.datetime "created_at", null: false
    t.text "error"
    t.json "input", default: {}, null: false
    t.string "kind", null: false
    t.integer "max_attempts", default: 5, null: false
    t.json "output"
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["correlation_id"], name: "index_operations_on_correlation_id"
    t.index ["kind", "status"], name: "index_operations_on_kind_and_status"
    t.index ["status", "attempt_count"], name: "index_operations_on_status_and_attempt_count"
  end

  create_table "receipts", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.string "country"
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.float "ocr_confidence"
    t.date "paid_on", null: false
    t.datetime "updated_at", null: false
    t.string "vendor"
    t.index ["paid_on"], name: "index_receipts_on_paid_on"
  end

  create_table "received_documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.string "sender"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_received_documents_on_kind"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bank_transactions", "filings", column: "matched_filing_id"
  add_foreign_key "filings", "users"
  add_foreign_key "issued_invoice_line_items", "issued_invoices"
  add_foreign_key "sessions", "users"
end
