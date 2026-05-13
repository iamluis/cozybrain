class IssuedInvoice < ApplicationRecord
  include Filable

  STATUSES        = %w[ draft approved sent paid ].freeze
  TAX_TREATMENTS  = Client::TAX_TREATMENTS

  belongs_to :client

  has_many :line_items,
           -> { order(:position) },
           class_name: "IssuedInvoiceLineItem",
           inverse_of: :issued_invoice,
           dependent: :destroy
  accepts_nested_attributes_for :line_items, allow_destroy: true, reject_if: :all_blank
  has_one_attached :pdf

  before_validation :sync_period_from_service_period
  before_validation :normalize_blank_tax_treatment
  before_validation :renumber_line_items
  after_update :sync_filing_period,
               if: -> { saved_change_to_service_period_end? || saved_change_to_service_period_start? }

  validates :number,         presence: true, uniqueness: true
  validates :amount_cents,   presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency,       presence: true, length: { is: 3 }
  validates :invoice_status, inclusion: { in: STATUSES }
  validates :tax_treatment,  inclusion: { in: TAX_TREATMENTS }, allow_nil: true
  validates :service_period_start, :service_period_end, presence: true
  validate  :service_period_order

  STATUSES.each do |s|
    define_method("invoice_#{s}?") { invoice_status == s }
  end

  # Effective values: invoice override wins, else client default.
  def effective_tax_treatment
    tax_treatment.presence || client.default_tax_treatment
  end

  def effective_payment_terms_days
    payment_terms_days || client.default_payment_terms_days
  end

  def effective_iban
    iban_override.presence || client.default_iban
  end

  # Drafts always read the live client name. Once sent, the snapshot
  # (`client_name`) freezes so a later client rename doesn't rewrite
  # history.
  def display_client_name
    if invoice_draft? || invoice_approved?
      client&.legal_name
    else
      client_name.presence || client&.legal_name
    end
  end

  # Money. Internal storage is *_cents (int); decimals are computed.
  def subtotal_cents
    line_items.to_a.sum { |li| (li.quantity * li.unit_amount_cents).to_i }
  end

  def tax_rate
    effective_tax_treatment == "domestic_vat_21" ? BigDecimal("0.21") : BigDecimal("0")
  end

  def tax_amount_cents
    (subtotal_cents * tax_rate).round
  end

  def total_cents
    subtotal_cents + tax_amount_cents
  end

  def subtotal   = BigDecimal(subtotal_cents) / 100
  def tax_amount = BigDecimal(tax_amount_cents) / 100
  def total      = BigDecimal(total_cents) / 100

  def recompute_total!
    update!(amount_cents: total_cents)
  end

  def period_label
    return "—" unless service_period_end
    if service_period_start.year == service_period_end.year &&
       service_period_start.month == service_period_end.month
      I18n.l(service_period_end, format: "%B %Y")
    else
      "#{I18n.l(service_period_start, format: '%-d %b')} – #{I18n.l(service_period_end, format: '%-d %b %Y')}"
    end
  end

  def self.next_number_for(year:)
    prefix = year.to_s
    last = where("number LIKE ?", "#{prefix}-%").order(number: :desc).first
    next_seq = last ? last.number.split("-").last.to_i + 1 : 1
    "#{prefix}-#{next_seq.to_s.rjust(4, '0')}"
  end

  # Clones the previous invoice's structure into a fresh draft for the
  # given client + month. Defaults: period = full month, treatment +
  # terms = client's defaults. Returns the new draft (unsaved if invalid).
  def self.draft_next(user:, client:, period_year:, period_month:)
    template = where(client: client).order(:period_year, :period_month).last
    start_d  = Date.new(period_year, period_month, 1)
    end_d    = start_d.end_of_month

    draft = new(
      client:               client,
      number:               next_number_for(year: period_year),
      issued_on:            nil,
      amount_cents:         0,
      currency:             template&.currency || "EUR",
      service_period_start: start_d,
      service_period_end:   end_d,
      tax_treatment:        nil,
      invoice_status:       "draft"
    )

    (template&.line_items || []).each_with_index do |li, idx|
      next_desc = template ? li.description.gsub(template.period_label, draft.period_label) : li.description
      draft.line_items.build(
        position:          idx + 1,
        description:       next_desc,
        quantity:          li.quantity,
        unit_amount_cents: li.unit_amount_cents
      )
    end

    draft.build_filing(
      user:         user,
      folder:       "issued",
      period_year:  end_d.year,
      period_month: end_d.month,
      status:       "pending",
      source:       "manual",
      received_at:  Time.current
    )

    draft.amount_cents = draft.line_items.sum { |li| (li.quantity * li.unit_amount_cents).to_i }
    draft
  end

  private

  def normalize_blank_tax_treatment
    self.tax_treatment = nil if tax_treatment.blank?
  end

  # Re-sequence line item positions so newly-added rows don't collide on
  # the (issued_invoice_id, position) uniqueness scope. The form template
  # hardcodes position=99 for new rows; adding two in a row used to fail
  # validation silently.
  def renumber_line_items
    line_items.reject(&:marked_for_destruction?).each_with_index do |li, i|
      li.position = i + 1
    end
  end

  def sync_period_from_service_period
    return unless service_period_end
    self.period_year  = service_period_end.year
    self.period_month = service_period_end.month
  end

  def sync_filing_period
    return unless service_period_end
    filing&.update_columns(period_year: service_period_end.year, period_month: service_period_end.month)
  end

  def service_period_order
    return if service_period_start.blank? || service_period_end.blank?
    errors.add(:service_period_end, "must be on or after the start date") if service_period_end < service_period_start
  end
end
