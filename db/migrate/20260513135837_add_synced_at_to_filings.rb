class AddSyncedAtToFilings < ActiveRecord::Migration[8.1]
  def change
    add_column :filings, :synced_at, :datetime
    add_index  :filings, :synced_at
  end
end
