class Receipt < ApplicationRecord
  include Filable

  COUNTRIES = %w[ ES BE FR NL DE PT IT GB US ].freeze

  attribute :amount, :decimal

  has_one_attached :original_photo
  has_one_attached :certified_pdf

  before_validation :sync_amount_cents

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :currency,     presence: true, length: { is: 3 }
  validates :paid_on,      presence: true

  def amount
    super || (amount_cents && BigDecimal(amount_cents) / 100)
  end

  private

  def sync_amount_cents
    return if amount.blank?
    self.amount_cents = (amount * 100).to_i
  end
end
