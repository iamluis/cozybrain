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

  # Title for a stream entry — vendor / subject / client+number.
  def stream_entry_title(entry)
    case entry.proof_side&.filable
    when Receipt
      entry.proof_side.filable.vendor.presence || "Receipt"
    when ReceivedDocument
      doc = entry.proof_side.filable
      doc.subject.presence || doc.kind.humanize
    when IssuedInvoice
      inv = entry.proof_side.filable
      "#{inv.display_client_name} · #{inv.number}"
    else
      entry.money_side&.description.presence || "Bank transaction"
    end
  end

  # Returns the inline meta parts (kind, locale, photo, matched, note) as
  # an array; the view joins them with mono `·` separators.
  def stream_entry_meta_parts(entry)
    parts = []
    parts << ledger_kind_label(entry).downcase
    parts << stream_entry_locale(entry) if stream_entry_locale(entry)
    parts << "photo"   if stream_entry_has_photo?(entry)
    parts << "note"    if stream_entry_note(entry)
    parts << "matched" if entry.both_sides?
    parts
  end

  def stream_entry_locale(entry)
    case entry.proof_side&.filable
    when Receipt           then entry.proof_side.filable.country.presence
    when ReceivedDocument  then entry.proof_side.filable.sender.presence
    when IssuedInvoice     then nil
    end
  end

  def stream_entry_has_photo?(entry)
    entry.proof_side&.filable.is_a?(Receipt) &&
      entry.proof_side.filable.original_photo.attached?
  end

  def stream_entry_note(entry)
    entry.proof_side&.note.presence
  end

  # LedgerHelper is part of the same view chain so its methods are
  # available here without explicit include.
  def ledger_kind_label_from_entry(entry)
    ledger_kind_label(entry)
  end

  private

  def formatted_amount(cents)
    return nil if cents.nil?
    euros = cents.abs / 100.0
    # Thousands separator via Rails helper; sign-and-currency manually for
    # consistent placement: "−€23,455.00" / "+€8,000.00".
    formatted = number_with_precision(euros, precision: 2, delimiter: ",")
    sign = cents.negative? ? "−" : "+"   # real minus glyph for typographic feel
    "#{sign}€#{formatted}"
  end
end
