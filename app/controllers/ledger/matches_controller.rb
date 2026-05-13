module Ledger
  # Match a bank transaction to a Filing (a Receipt's filing, today; later
  # an invoice's, if the bank-side ever appears before the proof). The
  # `new` view lists candidate filings ranked by closeness; `create` writes
  # the match.
  class MatchesController < ApplicationController
    layout "app"

    AMOUNT_TOLERANCE_CENTS = 500   # ±€5 — wider than Entry's "proven" tolerance
    DATE_TOLERANCE_DAYS    = 7

    def new
      @txn        = BankTransaction.find(params[:bank_transaction_id])
      @candidates = candidates_for(@txn)
    end

    def create
      txn    = BankTransaction.find(params[:bank_transaction_id])
      filing = Filing.find(params[:filing_id])
      txn.update!(matched_filing: filing)
      redirect_to home_path, notice: "Matched to #{filing.filable.try(:vendor) || filing.filable_type}."
    end

    private

    def candidates_for(txn)
      target_cents = txn.amount_cents.abs
      target_date  = txn.posted_on

      Filing.untrashed
            .joins("LEFT OUTER JOIN bank_transactions ON bank_transactions.matched_filing_id = filings.id")
            .where("bank_transactions.id IS NULL OR bank_transactions.id = ?", txn.id)
            .includes(:filable)
            .select { |f| f.filable.respond_to?(:amount_cents) && f.filable.amount_cents.present? }
            .map    { |f| [ f, distance(f, target_cents, target_date) ] }
            .reject { |_, d| d.nil? }
            .sort_by { |_, d| d }
            .first(20)
            .map(&:first)
    end

    # Combined distance: amount delta (in cents) + day delta * 200. Lower
    # is closer. nil if either side is too far away to bother listing.
    def distance(filing, target_cents, target_date)
      diff_cents = (filing.filable.amount_cents.abs - target_cents).abs
      return nil if diff_cents > AMOUNT_TOLERANCE_CENTS

      diff_days = (filing.received_at.to_date - target_date).abs
      return nil if diff_days > DATE_TOLERANCE_DAYS

      diff_cents + diff_days * 200
    end
  end
end
