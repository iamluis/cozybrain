# A single user-facing event in the books: at most one bank-side line and
# at most one proof-side filing. Wraps the two and exposes a derived state
# (proven / open / dismissed) and a kind (income / expense / tax / corporate
# / transfer / unknown).
#
# Underneath: the technical statuses on Filing, IssuedInvoice, and
# BankTransaction keep doing their job. Ledger::Entry exists so the user
# only needs to learn three words.
#
# Used by Home (stream + tray) and the match UI.
module Ledger
  class Entry
    STATES = %i[ proven open dismissed ].freeze
    KINDS  = %i[ income expense tax corporate transfer unknown ].freeze

    AMOUNT_TOLERANCE_CENTS = 1     # ±€0.01
    DATE_TOLERANCE_DAYS    = 7

    attr_reader :money_side, :proof_side

    def self.from_filing(filing)
      new(filing: filing, bank_transaction: filing.matched_bank_transaction)
    end

    def self.from_bank_transaction(txn)
      new(filing: txn.matched_filing, bank_transaction: txn)
    end

    def initialize(filing:, bank_transaction:)
      raise ArgumentError, "Ledger::Entry needs at least one side" if filing.nil? && bank_transaction.nil?
      @proof_side = filing
      @money_side = bank_transaction
    end

    # Proven means the user has nothing to do here. That's:
    #   · A proof side that's settled (not a draft invoice, not a needs-
    #     review inbound doc), AND
    #   · If a bank side is also present, the two sides agree on amount
    #     and date.
    # An unmatched bank transaction is Open (needs proof). A draft invoice
    # is Open (needs sending). A low-confidence inbound doc is Open (needs
    # filing).
    def state
      return :dismissed if dismissed?
      return :open      if proof_side.nil?            # money side only
      return :open      if draft_invoice?
      return :open      if needs_review_proof?
      return :open      if both_sides? && !sides_agree?
      :proven
    end

    def kind
      case proof_side&.filable
      when IssuedInvoice    then :income
      when Receipt          then :expense
      when ReceivedDocument then kind_from_received_document(proof_side.filable)
      else
        money_side ? kind_from_amount(money_side) : :unknown
      end
    end

    # The date the *event* happened — what the user thinks of as "when",
    # not when the system received the row.
    #
    #   Receipt          → paid_on              (date on the receipt)
    #   IssuedInvoice    → issued_on, else service_period_end
    #   ReceivedDocument → received_at (no better signal available)
    #   BankTransaction  → posted_on
    def at
      return money_side.posted_on if proof_side.nil?
      transaction_date_for(proof_side.filable) || proof_side.received_at.to_date
    end

    private

    def transaction_date_for(filable)
      case filable
      when Receipt
        filable.paid_on
      when IssuedInvoice
        filable.issued_on || filable.service_period_end
      end
    end

    public

    # Signed €: positive = inflow, negative = outflow.
    def amount_cents
      if proof_side&.filable.respond_to?(:amount_cents)
        cents = proof_side.filable.amount_cents
        # Receipts are expenses → negative sign.
        kind == :expense ? -cents.abs : cents.abs
      elsif money_side
        money_side.amount_cents
      end
    end

    def amount
      cents = amount_cents
      cents ? BigDecimal(cents) / 100 : nil
    end

    def proven?    = state == :proven
    def open?      = state == :open
    def dismissed? = proof_side&.trashed? || money_side&.dismissed?
    def both_sides? = proof_side.present? && money_side.present?

    # What needs to happen for this entry to become proven? Used by the
    # tray to pick a verb.
    def open_reason
      return nil unless open?
      case
      when proof_side.nil?                  then :needs_proof
      when draft_invoice?                   then :needs_send
      when needs_review_proof?              then :needs_review
      when both_sides? && !amounts_match?   then :amount_mismatch
      when both_sides? && !dates_close?     then :date_mismatch
      else :unknown
      end
    end

    private

    def sides_agree?
      amounts_match? && dates_close?
    end

    def amounts_match?
      return false unless both_sides?
      proof_cents = proof_side.filable.respond_to?(:amount_cents) ? proof_side.filable.amount_cents.abs : nil
      money_cents = money_side.amount_cents.abs
      proof_cents && (proof_cents - money_cents).abs <= AMOUNT_TOLERANCE_CENTS
    end

    def dates_close?
      return false unless both_sides?
      pd = proof_side.received_at.to_date
      md = money_side.posted_on
      (pd - md).abs <= DATE_TOLERANCE_DAYS
    end

    def kind_from_received_document(doc)
      case doc.kind
      when "tax_doc"        then :tax
      when "corporate"      then :corporate
      when "bank_statement" then :transfer
      else :expense
      end
    end

    def kind_from_amount(txn)
      txn.amount_cents.positive? ? :income : :expense
    end

    def draft_invoice?
      proof_side&.filable.is_a?(IssuedInvoice) && proof_side.filable.invoice_status == "draft"
    end

    def needs_review_proof?
      proof_side&.status == "needs_review"
    end
  end
end
