module StreamHelper
  def stream_day_label(date)
    case date
    when Date.current   then "Today"
    when Date.yesterday then "Yesterday"
    else
      I18n.l(date, format: date.year == Date.current.year ? "%B %-d" : "%B %-d, %Y")
    end
  end

  # Time-of-day for an entry's proof side; "—" for bank-only entries.
  def stream_entry_time(entry)
    entry.proof_side&.received_at&.strftime("%H:%M") || "—"
  end

  def stream_entry_amount(entry)
    formatted_amount(entry.amount_cents)
  end

  def stream_entry_amount_class(entry)
    cents = entry.amount_cents
    return nil if cents.nil?
    cents.negative? ? "entry__amount entry__amount--negative" : "entry__amount entry__amount--positive"
  end

  def stream_entry_target(entry)
    case entry.proof_side&.filable
    when Receipt       then receipt_path(entry.proof_side.filable)
    when IssuedInvoice then invoice_path(entry.proof_side.filable)
    end
  end

  private

  def formatted_amount(cents)
    return nil if cents.nil?
    sign = cents.negative? ? "-" : "+"
    "#{sign}€#{format('%.2f', cents.abs / 100.0)}"
  end
end
