class IssuedInvoice < ApplicationRecord
  include Filable

  STATUSES = %w[ draft approved sent paid ].freeze

  has_many :line_items,
           -> { order(:position) },
           class_name: "IssuedInvoiceLineItem",
           inverse_of: :issued_invoice,
           dependent: :destroy
  accepts_nested_attributes_for :line_items, allow_destroy: true, reject_if: :all_blank
  has_one_attached :pdf

  validates :client_name,    presence: true
  validates :number,         presence: true, uniqueness: true
  validates :amount_cents,   presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency,       presence: true, length: { is: 3 }
  validates :period_year,    presence: true, numericality: { only_integer: true }
  validates :period_month,   presence: true, numericality: { only_integer: true, in: 1..12 }
  validates :invoice_status, inclusion: { in: STATUSES }

  STATUSES.each do |s|
    define_method("invoice_#{s}?") { invoice_status == s }
  end

  def computed_total_cents
    line_items.to_a.sum { |li| (li.quantity * li.unit_amount_cents).to_i }
  end

  def recompute_total!
    update!(amount_cents: computed_total_cents)
  end

  def period_label
    Date.new(period_year, period_month, 1).strftime("%B %Y")
  end

  def self.next_number_for(year:)
    prefix = year.to_s
    last = where("number LIKE ?", "#{prefix}-%").order(number: :desc).first
    next_seq = last ? last.number.split("-").last.to_i + 1 : 1
    "#{prefix}-#{next_seq.to_s.rjust(4, '0')}"
  end

  # Clones the most recent invoice's structure into a fresh draft for the
  # given period. Returns the new draft (unsaved if invalid).
  def self.draft_next(user:, period_year:, period_month:)
    template = order(:period_year, :period_month).last

    draft = new(
      client_name:    template&.client_name || "Lab900",
      number:         next_number_for(year: period_year),
      issued_on:      nil,
      amount_cents:   0,
      currency:       template&.currency || "EUR",
      period_year:    period_year,
      period_month:   period_month,
      invoice_status: "draft"
    )

    (template&.line_items || []).each_with_index do |li, idx|
      draft.line_items.build(
        position:          idx + 1,
        description:       li.description.gsub(/\b#{Regexp.escape(template.period_label)}\b/, draft.period_label),
        quantity:          li.quantity,
        unit_amount_cents: li.unit_amount_cents
      )
    end

    draft.build_filing(
      user:         user,
      folder:       "issued",
      period_year:  period_year,
      period_month: period_month,
      status:       "pending",
      source:       "manual",
      received_at:  Time.current
    )

    draft.amount_cents = draft.line_items.sum { |li| (li.quantity * li.unit_amount_cents).to_i }
    draft
  end
end
