class CreateReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :receipts do |t|
      t.string  :vendor
      t.integer :amount_cents,    null: false
      t.string  :currency,        null: false, default: "EUR"
      t.date    :paid_on,         null: false
      t.string  :country
      t.float   :ocr_confidence

      t.timestamps
    end

    add_index :receipts, :paid_on
  end
end
