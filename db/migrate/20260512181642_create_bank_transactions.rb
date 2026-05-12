class CreateBankTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_transactions do |t|
      t.date    :posted_on,         null: false
      t.integer :amount_cents,      null: false
      t.string  :currency,          null: false, default: "EUR"
      t.string  :description
      t.string  :holded_ref,        null: false
      t.references :matched_filing, foreign_key: { to_table: :filings }

      t.timestamps
    end

    add_index :bank_transactions, :holded_ref, unique: true
    add_index :bank_transactions, :posted_on
  end
end
