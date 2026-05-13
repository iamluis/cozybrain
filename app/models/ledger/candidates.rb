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
      cents_min    = [ target_cents - AMOUNT_TOLERANCE_CENTS, 0 ].max
      cents_max    = target_cents + AMOUNT_TOLERANCE_CENTS
      date_min     = target_date - DATE_TOLERANCE_DAYS.days
      date_max     = target_date + DATE_TOLERANCE_DAYS.days

      # SQL-level scope by amount + date window so we don't load every
      # Filing and filter in Ruby. Polymorphic, so query both filable
      # tables via UNION semantics — split into two queries.
      receipt_ids = Receipt.where(amount_cents: cents_min..cents_max).pluck(:id)
      invoice_ids = IssuedInvoice.where(amount_cents: cents_min..cents_max).pluck(:id)

      filable_clause = []
      filable_args   = []
      if receipt_ids.any?
        filable_clause << "(filable_type = 'Receipt' AND filable_id IN (?))"
        filable_args   << receipt_ids
      end
      if invoice_ids.any?
        filable_clause << "(filable_type = 'IssuedInvoice' AND filable_id IN (?))"
        filable_args   << invoice_ids
      end
      return [] if filable_clause.empty?

      candidates = Filing.untrashed
        .joins("LEFT OUTER JOIN bank_transactions ON bank_transactions.matched_filing_id = filings.id")
        .where("bank_transactions.id IS NULL OR bank_transactions.id = ?", txn.id)
        .where(received_at: date_min.beginning_of_day..date_max.end_of_day)
        .where(filable_clause.join(" OR "), *filable_args)
        .includes(:filable)

      candidates
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
