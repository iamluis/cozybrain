class AddRealFieldsToIssuedInvoices < ActiveRecord::Migration[8.1]
  def change
    # client_id is nullable at the DB level for the migration window;
    # model-level validation enforces presence. We backfill via the seed.
    add_reference :issued_invoices, :client, foreign_key: true
    add_column :issued_invoices, :service_period_start, :date
    add_column :issued_invoices, :service_period_end,   :date
    add_column :issued_invoices, :tax_treatment,        :string
    add_column :issued_invoices, :payment_terms_days,   :integer
    add_column :issued_invoices, :iban_override,        :string
    add_column :issued_invoices, :notes,                :text
  end
end
