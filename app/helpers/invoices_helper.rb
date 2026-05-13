module InvoicesHelper
  TAX_TREATMENT_LABELS = {
    "intra_eu_reverse_charge" => "Intra-EU reverse charge (no VAT)",
    "domestic_vat_21"         => "Spain · IVA 21%",
    "exempt"                  => "Exempt"
  }.freeze

  TAX_TREATMENT_LEGAL_MENTIONS = {
    "intra_eu_reverse_charge" => "Operación intracomunitaria. Inversión del sujeto pasivo — Art. 196 Directiva 2006/112/CE.",
    "exempt"                  => "Operación exenta de IVA conforme a la Ley 37/1992."
  }.freeze

  def tax_treatment_label(treatment)
    TAX_TREATMENT_LABELS[treatment] || treatment.to_s.humanize
  end

  def invoice_legal_mention(invoice)
    TAX_TREATMENT_LEGAL_MENTIONS[invoice.effective_tax_treatment]
  end

  # Format a quantity for an editable field. Integer if whole, otherwise
  # trim trailing zeros. No locale comma — the field stays in `.` form
  # for clean parsing and consistent rendering across browser locales.
  def format_quantity(value)
    return "" if value.blank?
    decimal = value.to_d
    if decimal == decimal.truncate
      decimal.to_i.to_s
    else
      decimal.to_s("F").sub(/0+$/, "").sub(/\.$/, "")
    end
  end

  # Always 2 decimals, dot-separator, no thousands grouping. Money-like.
  def format_money(value)
    return "" if value.blank?
    format("%.2f", value.to_d)
  end

  # Display formatter (read-only): €1,234.56 with thousands separator.
  def display_money(value)
    return "—" if value.blank?
    "€" + number_with_precision(value, precision: 2, delimiter: ",")
  end
end
