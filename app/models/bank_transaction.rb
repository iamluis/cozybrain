class BankTransaction < ApplicationRecord
  belongs_to :matched_filing,
             class_name: "Filing",
             optional: true,
             inverse_of: :matched_bank_transaction

  validates :posted_on,    presence: true
  validates :amount_cents, presence: true, numericality: { only_integer: true }
  validates :currency,     presence: true, length: { is: 3 }
  validates :holded_ref,   presence: true, uniqueness: true

  scope :active,    -> { where(dismissed_at: nil) }
  scope :dismissed, -> { where.not(dismissed_at: nil) }
  scope :unmatched, -> { active.where(matched_filing_id: nil) }
  scope :matched,   -> { active.where.not(matched_filing_id: nil) }

  def dismissed? = dismissed_at.present?
  def dismiss!   = update!(dismissed_at: Time.current)

  def matched? = matched_filing_id.present?
end
