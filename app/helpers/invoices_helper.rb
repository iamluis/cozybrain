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
end
