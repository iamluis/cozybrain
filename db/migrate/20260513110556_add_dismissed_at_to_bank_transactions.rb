class AddDismissedAtToBankTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :bank_transactions, :dismissed_at, :datetime
    add_index  :bank_transactions, :dismissed_at
  end
end
