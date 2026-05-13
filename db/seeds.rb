# Idempotent: safe to run repeatedly.

Client.find_or_create_by!(legal_name: "Lab900") do |c|
  c.country                     = "BE"
  c.default_tax_treatment       = "intra_eu_reverse_charge"
  c.default_payment_terms_days  = 30
end

# Backfill: every existing invoice that came from before this milestone is
# Lab900's. The model validates client presence, so without this the test
# suite breaks after migration.
lab900 = Client.find_by!(legal_name: "Lab900")
IssuedInvoice.where(client_id: nil).find_each do |inv|
  start_d = Date.new(inv.period_year, inv.period_month, 1)
  inv.update_columns(
    client_id:            lab900.id,
    tax_treatment:        lab900.default_tax_treatment,
    service_period_start: start_d,
    service_period_end:   start_d.end_of_month
  )
end
