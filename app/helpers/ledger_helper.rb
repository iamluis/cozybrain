module LedgerHelper
  STATE_LABELS = {
    proven:     "Filed",
    dismissed:  "Dismissed"
  }.freeze

  OPEN_REASON_LABELS = {
    needs_proof:      "Match a receipt",
    needs_send:       "Send to client",
    needs_review:     "File this",
    awaiting_bank:    "Waiting for bank",
    amount_mismatch:  "Amount doesn't match",
    date_mismatch:    "Date is off",
    unknown:          "Needs attention"
  }.freeze

  # User-facing state label. Plain English; no enum strings.
  def ledger_state_label(entry)
    case entry.state
    when :proven, :dismissed
      STATE_LABELS[entry.state]
    when :open
      OPEN_REASON_LABELS[entry.open_reason] || OPEN_REASON_LABELS[:unknown]
    end
  end

  # One-word verb that describes the user's job on an Open entry. Used by
  # tray rows for the primary action button.
  def ledger_state_verb(entry)
    return nil unless entry.open?
    case entry.open_reason
    when :needs_proof  then "Match"
    when :needs_send   then "Send"
    when :needs_review then "File"
    else nil
    end
  end

  # Tiny label for the kind, used by stream rows + tray rows.
  def ledger_kind_label(entry)
    case entry.kind
    when :income     then "Income"
    when :expense    then "Expense"
    when :tax        then "Tax"
    when :corporate  then "Corporate"
    when :transfer   then "Transfer"
    else                  "Unknown"
    end
  end
end
