module Ledger
  # Match a bank transaction to a Filing. The `new` view lists candidate
  # filings ranked by closeness (used as a fallback when the tray can't
  # surface a confident inline candidate). `create` writes the match.
  class MatchesController < ApplicationController
    layout "app"

    def new
      @txn        = BankTransaction.find(params[:bank_transaction_id])
      @candidates = Ledger::Candidates.for_bank_transaction(@txn)
    end

    def create
      txn    = BankTransaction.find(params[:bank_transaction_id])
      filing = Filing.find(params[:filing_id])
      txn.update!(matched_filing: filing)
      redirect_to home_path, notice: "Matched to #{filing.filable.try(:vendor) || filing.filable_type}."
    end
  end
end
