class IssuedInvoiceLineItem < ApplicationRecord
  belongs_to :issued_invoice, inverse_of: :line_items

  validates :position,          presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :description,       presence: true
  validates :quantity,          presence: true, numericality: { greater_than: 0 }
  validates :unit_amount_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :position, uniqueness: { scope: :issued_invoice_id }

  def total_cents
    (quantity * unit_amount_cents).round
  end
end
