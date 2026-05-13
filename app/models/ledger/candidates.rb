# Finds the best-match Filing candidates for an unmatched BankTransaction.
# Used by the inline tray (top candidate) AND the match-candidates page
# (full list).
#
# Ranking: combined distance of (amount_diff_cents, date_diff_days * 200).
# Lower is closer. Returns at most `limit` results within the tolerance
# windows; empty array if no filing is close enough.
module Ledger
  module Candidates
    AMOUNT_TOLERANCE_CENTS = 500   # ±€5
    DATE_TOLERANCE_DAYS    = 7

    module_function

    def for_bank_transaction(txn, limit: 20)
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
            .first(limit)
            .map(&:first)
    end

    def distance(filing, target_cents, target_date)
      diff_cents = (filing.filable.amount_cents.abs - target_cents).abs
      return nil if diff_cents > AMOUNT_TOLERANCE_CENTS

      diff_days = (filing.received_at.to_date - target_date).abs
      return nil if diff_days > DATE_TOLERANCE_DAYS

      diff_cents + diff_days * 200
    end
  end
end
