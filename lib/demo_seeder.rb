# Builds a realistic, repeatable multi-year dataset for one demo user.
# Idempotent — running again wipes the user's data and regenerates from
# the same RNG seed, so the result is byte-identical across runs.
#
#   DemoSeeder.new(email: "demo@cozyedge.tech", password: "x", years_back: 3).run!
class DemoSeeder
  attr_reader :user, :client, :rng

  def initialize(email:, password:, years_back: 3)
    @email       = email
    @password    = password
    @years_back  = years_back
    @rng         = Random.new(seed_from(email))
  end

  def run!
    puts "→ demo seed for #{@email} (#{@years_back} years)"
    @user   = upsert_user
    @client = ensure_client
    wipe_user_data!
    seed_months_of_business!
    print_summary
  end

  private

  # ---- bootstrap ------------------------------------------------------

  def seed_from(email)
    # Stable seed derived from the email so the data is the same across runs.
    Digest::SHA256.hexdigest(email)[0..15].to_i(16)
  end

  def upsert_user
    u = User.find_or_initialize_by(email_address: @email)
    u.password = @password
    u.save!
    u
  end

  def ensure_client
    Client.find_or_create_by!(legal_name: "Lab900") do |c|
      c.country                     = "BE"
      c.vat_number                  = "BE0707.779.108"
      c.address                     = "Lange Leemstraat 374\n2600 Antwerpen-Berchem\nBelgium"
      c.contact_email               = "info@lab900.com"
      c.default_tax_treatment       = "intra_eu_reverse_charge"
      c.default_payment_terms_days  = 30
      c.default_iban                = "ES12 3456 7890 1234 5678 9012"
    end
  end

  def wipe_user_data!
    Filing.where(user_id: @user.id).find_each do |f|
      f.filable&.destroy
      f.destroy
    end
    # Drop bank transactions that aren't pointing at someone else's filing.
    # In single-user demo there's only one user, so all of them.
    BankTransaction.where(matched_filing_id: nil).destroy_all
    BankTransaction.left_joins(:matched_filing).where(filings: { id: nil }).destroy_all
  end

  # ---- the time loop --------------------------------------------------

  def seed_months_of_business!
    months.each { |month_start| seed_month(month_start) }
    seed_quarterly_tax_docs!
    seed_open_attention_items!
  end

  def months
    finish  = Date.current.beginning_of_month
    start   = (finish << (12 * @years_back)).beginning_of_month
    Enumerator.new do |y|
      cur = start
      while cur <= finish
        y << cur
        cur = cur.next_month
      end
    end
  end

  # ---- per-month --------------------------------------------------------

  def seed_month(month_start)
    seed_monthly_invoice(month_start) unless future?(month_start)
    seed_monthly_receipts(month_start)
    seed_monthly_bank_inflow(month_start) unless future?(month_start)
  end

  def future?(month_start) = month_start > Date.current.beginning_of_month

  def seed_monthly_invoice(month_start)
    period_end    = month_start.end_of_month
    working_days  = pick(15..22)
    rate_eur      = pick([ 600, 650, 700, 750, 800 ])

    inv = IssuedInvoice.new(
      client:               @client,
      number:               next_invoice_number(month_start.year),
      currency:             "EUR",
      service_period_start: month_start,
      service_period_end:   period_end,
      tax_treatment:        "intra_eu_reverse_charge",
      invoice_status:       past_full_month?(month_start) ? "sent"  : "draft",
      issued_on:            past_full_month?(month_start) ? period_end : nil,
      client_name:          past_full_month?(month_start) ? "Lab900" : nil,
      payment_terms_days:   30,
      verifactu_ref:        past_full_month?(month_start) ? "vf-demo-#{SecureRandom.hex(4)}" : nil
    )
    inv.line_items.build(
      position:          1,
      description:       "Consulting services — #{Date::MONTHNAMES[month_start.month]} #{month_start.year}",
      quantity:          working_days,
      unit_amount_cents: rate_eur * 100
    )
    inv.amount_cents = working_days * rate_eur * 100
    inv.build_filing(
      user:         @user,
      folder:       "issued",
      period_year:  month_start.year,
      period_month: month_start.month,
      received_at:  period_end.to_time + 9.hours,
      filed_at:     past_full_month?(month_start) ? (period_end + 1.day).to_time : nil,
      status:       past_full_month?(month_start) ? "filed" : "pending",
      source:       "manual",
      holded_ref:   past_full_month?(month_start) ? "demo-inv-#{SecureRandom.hex(4)}" : nil
    )
    inv.save!
  end

  def past_full_month?(month_start)
    month_start.end_of_month < Date.current
  end

  def next_invoice_number(year)
    prefix = year.to_s
    last   = IssuedInvoice.where("number LIKE ?", "#{prefix}-%").order(number: :desc).first
    next_seq = last ? last.number.split("-").last.to_i + 1 : 1
    "#{prefix}-#{next_seq.to_s.rjust(4, '0')}"
  end

  def seed_monthly_receipts(month_start)
    count = future?(month_start) ? 0 : pick(8..14)
    count.times do
      day      = pick(1..[ 28, Date.current.day ].min)
      day      = pick(1..[ 28, month_start.end_of_month.day ].min) unless month_start.month == Date.current.month && month_start.year == Date.current.year
      paid_on  = month_start.change(day: day)
      next if paid_on > Date.current
      seed_receipt(paid_on)
    end
  end

  def seed_receipt(paid_on)
    vendor, amount_eur, country, note = receipt_template
    cents = (amount_eur * 100).to_i

    r = Receipt.new(
      vendor:       vendor,
      amount_cents: cents,
      currency:     "EUR",
      paid_on:      paid_on,
      country:      country
    )
    r.build_filing(
      user:         @user,
      folder:       "expenses",
      period_year:  paid_on.year,
      period_month: paid_on.month,
      received_at:  paid_on.to_time + pick(8..21).hours + pick(0..59).minutes,
      filed_at:     paid_on.to_time + 1.day,
      status:       "filed",
      source:       "capture",
      note:         note
    )
    r.save!

    # Attach a placeholder photo to ~70% of receipts. Skip for some so
    # the PHOTO meta-tag varies across the stream.
    attach_sample_photo(r) if rand_take(70)

    # Generate matching bank transaction for ~85% of them.
    if rand_take(85)
      seed_bank_transaction(
        amount_cents:  -cents,
        posted_on:     paid_on + pick(0..2).days,
        description:   bank_description_for(vendor, country),
        matched_filing: r.filing
      )
    end
  end

  def seed_monthly_bank_inflow(month_start)
    # Lab900 pays the previous month's invoice ~5–15 days into the new month.
    prev = month_start - 1.month
    inv_filing = Filing.where(filable_type: "IssuedInvoice", period_year: prev.year, period_month: prev.month).first
    return if inv_filing.nil? || inv_filing.filable.invoice_status == "draft"

    paid_on = month_start + pick(5..15).days
    return if paid_on > Date.current
    seed_bank_transaction(
      amount_cents:    inv_filing.filable.amount_cents,
      posted_on:       paid_on,
      description:     "TRANSFER FROM LAB900 NV — REF #{inv_filing.filable.number}",
      matched_filing:  inv_filing
    )
  end

  # ---- needs-attention items ------------------------------------------

  def seed_open_attention_items!
    # Three or four unmatched recent bank charges (tray fodder).
    pick(3..5).times do
      days_ago = pick(1..30)
      posted_on = Date.current - days_ago.days
      vendor, amount, _, _ = receipt_template
      seed_bank_transaction(
        amount_cents: -(amount * 100).to_i,
        posted_on:    posted_on,
        description:  bank_description_for(vendor, pick(%w[ ES BE NL DE FR ])),
        matched_filing: nil
      )
    end

    # One or two received-document filings that landed in needs_review.
    pick(1..2).times do
      sender = pick(%w[ random-supplier@unknown.com info@some-vendor.eu hello@unclassified.com ])
      seed_received_document(
        kind:        "other",
        subject:     "Invoice receipt from #{sender.split('@').last.split('.').first.titleize}",
        sender:      sender,
        folder:      "expenses",
        status:      "needs_review",
        received_at: (Date.current - pick(1..14).days).to_time + 11.hours
      )
    end
  end

  # ---- quarterly tax docs ---------------------------------------------

  def seed_quarterly_tax_docs!
    months.map { |m| Date.new(m.year, m.month, 1) }.uniq { |d| [ d.year, ((d.month - 1) / 3) + 1 ] }.each do |q_start|
      q       = ((q_start.month - 1) / 3) + 1
      doc_dt  = Date.new(q_start.year, ([ q * 3, 12 ].min), 25)
      next if doc_dt > Date.current

      seed_received_document(
        kind:        "tax_doc",
        subject:     "Modelo 303 Q#{q} #{q_start.year}",
        sender:      "gestoria@example.com",
        folder:      "tax",
        status:      "filed",
        received_at: doc_dt.to_time + 11.hours,
        period_quarter: q
      )
    end
  end

  def seed_received_document(kind:, subject:, sender:, folder:, status:, received_at:, period_quarter: nil)
    doc = ReceivedDocument.new(kind: kind, subject: subject, sender: sender)
    doc.build_filing(
      user:           @user,
      folder:         folder,
      period_year:    received_at.year,
      period_month:   period_quarter ? nil : received_at.month,
      period_quarter: period_quarter,
      received_at:    received_at,
      filed_at:       status == "filed" ? received_at + 1.day : nil,
      status:         status,
      source:         "email"
    )
    doc.save!
  end

  # ---- bank transactions ----------------------------------------------

  def seed_bank_transaction(amount_cents:, posted_on:, description:, matched_filing:)
    BankTransaction.create!(
      amount_cents:      amount_cents,
      currency:          "EUR",
      description:       description,
      posted_on:         posted_on,
      holded_ref:        "demo-tx-#{SecureRandom.hex(8)}",
      matched_filing:    matched_filing
    )
  end

  # ---- catalog of realistic vendors / patterns ------------------------

  def receipt_template
    bucket = weighted_pick(
      [ :coffee, 22 ],
      [ :lunch, 18 ],
      [ :saas, 14 ],
      [ :taxi, 10 ],
      [ :travel_flight, 7 ],
      [ :travel_hotel, 6 ],
      [ :supplies, 8 ],
      [ :coworking, 4 ],
      [ :restaurant, 8 ],
      [ :groceries, 3 ]
    )
    case bucket
    when :coffee        then [ pick(COFFEE),   pick(2.50..5.50).round(2),  pick(%w[ ES ES ES BE ]),       nil ]
    when :lunch         then [ pick(LUNCH),    pick(11.00..28.00).round(2), pick(%w[ ES ES ES BE BE NL ]), maybe(LUNCH_NOTES, 30) ]
    when :restaurant    then [ pick(DINNER),   pick(30.00..95.00).round(2), pick(%w[ ES BE NL FR ]),       maybe(DINNER_NOTES, 50) ]
    when :saas          then [ pick(SAAS),     pick(8.00..70.00).round(2),  "—",                          nil ]
    when :taxi          then [ "Cabify",       pick(6.00..28.00).round(2),  pick(%w[ ES BE ]),             "transport" ]
    when :travel_flight then [ pick(AIRLINES), pick(80.00..280.00).round(2), pick(%w[ ES BE ]),            "to BRU for Lab900" ]
    when :travel_hotel  then [ pick(HOTELS),   pick(85.00..240.00).round(2), "BE",                         "stay for Lab900 work" ]
    when :supplies      then [ pick(SUPPLIES), pick(12.00..120.00).round(2), pick(%w[ ES BE ]),            nil ]
    when :coworking     then [ "Talent Garden", pick(180.00..280.00).round(2), "ES",                       "monthly desk" ]
    when :groceries     then [ pick(GROCERIES), pick(14.00..68.00).round(2), "ES",                         nil ]
    end
  end

  def bank_description_for(vendor, country)
    cc = country == "—" ? "" : " #{country}"
    "#{vendor.upcase}#{cc}"
  end

  COFFEE     = [ "Café del Sol", "Hola Coffee", "Toma Café", "Misión Café", "El Café de la Esquina", "OR Coffee", "MOK Brussels", "Aksum Coffee" ].freeze
  LUNCH      = [ "Hannah", "Honest Greens", "La Manzana", "Mercado de la Reina", "Le Pain Quotidien", "EXKi", "Wagamama", "Vapiano", "Smaak" ].freeze
  DINNER     = [ "Bocconcini", "Asador Frontón", "Botánico", "Bar Brassens", "Le Stoffel", "Friture René", "Bia Mara", "Maison Antoine" ].freeze
  SAAS       = [ "GitHub", "Linear", "Vercel", "AWS", "Notion", "Figma", "Cloudflare", "Tailscale", "Fly.io", "Stripe", "Plausible", "1Password" ].freeze
  AIRLINES   = [ "Ryanair", "Vueling", "Brussels Airlines", "Iberia", "Air Europa" ].freeze
  HOTELS     = [ "citizenM Brussels", "MEININGER Brussels", "Mercure Antwerp", "Pentahotel", "Aparthotel Adagio" ].freeze
  SUPPLIES   = [ "MediaMarkt", "Worten", "FNAC", "Conforama", "Amazon" ].freeze
  GROCERIES  = [ "Mercadona", "Carrefour", "Lidl", "Aldi", "Ahorramas" ].freeze
  LUNCH_NOTES  = [ "with Matthias", "client lunch", "Lab900 catch-up", "team sync" ].freeze
  DINNER_NOTES = [ "Lab900 dinner", "client dinner", "team dinner — Brussels visit", "Lab900 quarterly review" ].freeze

  # ---- helpers --------------------------------------------------------

  def pick(range_or_array)
    case range_or_array
    when Array then range_or_array.sample(random: rng)
    when Range
      if range_or_array.begin.is_a?(Float)
        rng.rand(range_or_array)
      else
        rng.rand(range_or_array)
      end
    end
  end

  def rand_take(percent)
    rng.rand(0..99) < percent
  end

  def maybe(arr, percent) = rand_take(percent) ? pick(arr) : nil

  def weighted_pick(*pairs)
    total = pairs.sum { |_, w| w }
    r = rng.rand(total)
    cum = 0
    pairs.each do |label, w|
      cum += w
      return label if r < cum
    end
    pairs.last.first
  end

  def attach_sample_photo(receipt)
    sample = Rails.root.join("test/fixtures/files/sample_receipt.png")
    return unless File.exist?(sample)
    receipt.original_photo.attach(
      io:           File.open(sample),
      filename:     "receipt.png",
      content_type: "image/png"
    )
  end

  # ---- summary --------------------------------------------------------

  def print_summary
    puts "  user:        #{@user.email_address}"
    puts "  client:      #{@client.legal_name} (#{@client.vat_number})"
    puts "  invoices:    #{IssuedInvoice.count} (#{IssuedInvoice.where(invoice_status: 'draft').count} draft)"
    puts "  receipts:    #{Receipt.count}"
    puts "  inbound:     #{ReceivedDocument.count}"
    puts "  filings:     #{Filing.count} (#{Filing.needs_review.count} needs review)"
    puts "  bank txns:   #{BankTransaction.count} (#{BankTransaction.unmatched.count} unmatched)"
  end
end
