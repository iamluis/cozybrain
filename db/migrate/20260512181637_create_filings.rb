class CreateFilings < ActiveRecord::Migration[8.1]
  def change
    create_table :filings do |t|
      t.references :filable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true

      t.string   :folder,         null: false
      t.integer  :period_year,    null: false
      t.integer  :period_month
      t.integer  :period_quarter

      t.string   :status,         null: false, default: "pending"
      t.string   :source,         null: false
      t.datetime :received_at,    null: false
      t.datetime :filed_at
      t.datetime :trashed_at

      t.string   :holded_ref
      t.text     :note

      t.timestamps
    end

    add_index :filings, [ :filable_type, :filable_id ], unique: true, name: "idx_filings_on_filable_unique"
    add_index :filings, [ :user_id, :status ]
    add_index :filings, [ :folder, :period_year, :period_month ]
    add_index :filings, :holded_ref, unique: true, where: "holded_ref IS NOT NULL"
    add_index :filings, :trashed_at
  end
end
