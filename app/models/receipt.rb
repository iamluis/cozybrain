class Receipt < ApplicationRecord
  include Filable

  has_one_attached :original_photo
  has_one_attached :certified_pdf

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :currency,     presence: true, length: { is: 3 }
  validates :paid_on,      presence: true
end
