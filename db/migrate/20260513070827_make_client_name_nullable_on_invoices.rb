class MakeClientNameNullableOnInvoices < ActiveRecord::Migration[8.1]
  def change
    change_column_null :issued_invoices, :client_name, true
  end
end
