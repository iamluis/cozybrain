class CreateIssuedInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :issued_invoices do |t|
      t.string  :client_name,    null: false
      t.string  :number,         null: false
      t.date    :issued_on
      t.integer :amount_cents,   null: false
      t.string  :currency,       null: false, default: "EUR"
      t.integer :period_year,    null: false
      t.integer :period_month,   null: false
      t.string  :invoice_status, null: false, default: "draft"
      t.string  :verifactu_ref

      t.timestamps
    end

    add_index :issued_invoices, :number, unique: true
    add_index :issued_invoices, [ :period_year, :period_month ]
  end
end
