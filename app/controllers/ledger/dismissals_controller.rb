module Ledger
  # Marks a bank transaction as not-business. The user explicitly says
  # "this one isn't an expense or income — get it out of my tray."
  class DismissalsController < ApplicationController
    layout "app"

    def create
      txn = BankTransaction.find(params[:bank_transaction_id])
      txn.dismiss!
      redirect_to home_path, notice: "Dismissed."
    end
  end
end
