class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string  :legal_name,                null: false
      t.string  :vat_number
      t.text    :address
      t.string  :country
      t.string  :contact_email
      t.string  :default_iban
      t.string  :default_tax_treatment,     null: false, default: "intra_eu_reverse_charge"
      t.integer :default_payment_terms_days, default: 30
      t.text    :notes

      t.timestamps
    end

    add_index :clients, :legal_name, unique: true
  end
end
