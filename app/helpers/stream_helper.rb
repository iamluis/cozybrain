module StreamHelper
  def stream_day_label(date)
    case date
    when Date.current   then "Today"
    when Date.yesterday then "Yesterday"
    else
      I18n.l(date, format: date.year == Date.current.year ? "%B %-d" : "%B %-d, %Y")
    end
  end

  def stream_time_of(event)
    timestamp = event.is_a?(Filing) ? event.received_at : nil
    timestamp&.strftime("%H:%M")
  end

  def stream_amount(event)
    cents = signed_cents(event)
    cents && formatted_amount(cents)
  end

  def stream_amount_class(event)
    cents = signed_cents(event)
    return nil if cents.nil?
    cents.negative? ? "entry__amount entry__amount--negative" : "entry__amount entry__amount--positive"
  end

  def stream_amount_for_bank(txn)
    formatted_amount(txn.amount_cents)
  end

  def tray_partial_for(item)
    case item
    when Filing          then "homes/tray_inbound_doc"
    when IssuedInvoice   then "homes/tray_draft_invoice"
    when BankTransaction then "homes/tray_unmatched_transaction"
    end
  end

  private

  def signed_cents(event)
    case event
    when Filing
      case event.filable
      when Receipt       then -event.filable.amount_cents
      when IssuedInvoice then event.filable.amount_cents
      end
    when BankTransaction
      event.amount_cents
    end
  end

  def formatted_amount(cents)
    sign = cents.negative? ? "-" : "+"
    "#{sign}€#{format('%.2f', cents.abs / 100.0)}"
  end
end
