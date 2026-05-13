# Idempotent: safe to run repeatedly.

lab900 = Client.find_or_initialize_by(legal_name: "Lab900")
lab900.assign_attributes(
  country:                    "BE",
  default_tax_treatment:      "intra_eu_reverse_charge",
  default_payment_terms_days: 30,
  vat_number:                 "BE0707.779.108",
  address:                    "Lange Leemstraat 374\n2600 Antwerpen-Berchem\nBelgium",
  contact_email:              "info@lab900.com"
)
# Only fill IBAN if blank — never overwrite something the user has set.
lab900.default_iban ||= "ES00 0000 0000 0000 0000 0000  (replace)"
lab900.save!

# Backfill: every existing invoice from before this milestone is Lab900's.
IssuedInvoice.where(client_id: nil).find_each do |inv|
  start_d = Date.new(inv.period_year, inv.period_month, 1)
  inv.update_columns(
    client_id:            lab900.id,
    tax_treatment:        lab900.default_tax_treatment,
    service_period_start: start_d,
    service_period_end:   start_d.end_of_month
  )
end
