class IssuedInvoice < ApplicationRecord
  include Filable

  STATUSES = %w[ draft approved sent paid ].freeze

  has_many :line_items,
           -> { order(:position) },
           class_name: "IssuedInvoiceLineItem",
           inverse_of: :issued_invoice,
           dependent: :destroy
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
end
