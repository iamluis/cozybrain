class Client < ApplicationRecord
  TAX_TREATMENTS = %w[ intra_eu_reverse_charge domestic_vat_21 exempt ].freeze

  has_many :issued_invoices, dependent: :restrict_with_error

  validates :legal_name,            presence: true, uniqueness: true
  validates :default_tax_treatment, inclusion: { in: TAX_TREATMENTS }
  validates :default_payment_terms_days,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :country, length: { is: 2 }, allow_blank: true

  def to_s = legal_name
end
