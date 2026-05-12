class CreateIssuedInvoiceLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :issued_invoice_line_items do |t|
      t.references :issued_invoice, null: false, foreign_key: true
      t.integer    :position,           null: false
      t.string     :description,        null: false
      t.decimal    :quantity,           precision: 10, scale: 2, null: false, default: 1
      t.integer    :unit_amount_cents,  null: false

      t.timestamps
    end

    add_index :issued_invoice_line_items, [ :issued_invoice_id, :position ], unique: true, name: "idx_invoice_line_items_position_unique"
  end
end
