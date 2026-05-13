class IssuedInvoiceLineItem < ApplicationRecord
  belongs_to :issued_invoice, inverse_of: :line_items

  # Virtual €-based accessor. The form types it as a BigDecimal; we persist
  # cents (no float math, no precision loss). Mirrors Receipt#amount.
  attribute :unit_amount, :decimal

  before_validation :sync_unit_amount_cents

  validates :position,          presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :description,       presence: true
  validates :quantity,          presence: true, numericality: { greater_than: 0 }
  validates :unit_amount_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :position, uniqueness: { scope: :issued_invoice_id }

  def unit_amount
    super || (unit_amount_cents && BigDecimal(unit_amount_cents) / 100)
  end

  # Comma-tolerant setters — a Spanish user typing "650,00" or "1,5" gets
  # parsed correctly regardless of input locale.
  def unit_amount=(val)
    super(parse_decimal(val))
  end

  def quantity=(val)
    super(parse_decimal(val))
  end

  def total_cents
    (quantity * unit_amount_cents).round
  end

  def total
    BigDecimal(total_cents) / 100
  end

  private

  def parse_decimal(val)
    return val if val.nil? || val.is_a?(Numeric)
    cleaned = val.to_s.tr(",", ".")
    return nil if cleaned.empty?
    Float(cleaned)
  rescue ArgumentError, TypeError
    nil
  end

  def sync_unit_amount_cents
    return if unit_amount.blank?
    self.unit_amount_cents = (unit_amount * 100).to_i
  end
end
