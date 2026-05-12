module TimelineHelper
  def timeline_day_label(date)
    case date
    when Date.current   then "Today"
    when Date.yesterday then "Yesterday"
    else
      I18n.l(date, format: date.year == Date.current.year ? "%B %-d" : "%B %-d, %Y")
    end
  end

  def timeline_time_of(event)
    timestamp = event.is_a?(Filing) ? event.received_at : nil
    timestamp&.strftime("%H:%M")
  end

  def timeline_amount(event)
    cents = case event
    when Filing
              case event.filable
              when Receipt       then -event.filable.amount_cents
              when IssuedInvoice then event.filable.amount_cents
              end
    when BankTransaction
              event.amount_cents
    end

    return nil if cents.nil?
    formatted_amount(cents)
  end

  def timeline_amount_class(event)
    cents = case event
    when Filing
              case event.filable
              when Receipt       then -event.filable.amount_cents
              when IssuedInvoice then event.filable.amount_cents
              end
    when BankTransaction
              event.amount_cents
    end

    return nil if cents.nil?
    cents.negative? ? "entry__amount entry__amount--negative" : "entry__amount entry__amount--positive"
  end

  private

  def formatted_amount(cents)
    sign = cents.negative? ? "-" : "+"
    "#{sign}€#{format('%.2f', cents.abs / 100.0)}"
  end
end
