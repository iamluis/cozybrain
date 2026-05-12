class Filing < ApplicationRecord
  FOLDERS  = %w[ issued expenses bank tax corporate payroll ].freeze
  STATUSES = %w[ pending filed needs_review ].freeze
  SOURCES  = %w[ capture email holded_sync manual ].freeze

  belongs_to :filable, polymorphic: true, inverse_of: :filing
  belongs_to :user

  has_one :matched_bank_transaction,
          class_name: "BankTransaction",
          foreign_key: :matched_filing_id,
          inverse_of: :matched_filing,
          dependent: :nullify

  validates :folder,      inclusion: { in: FOLDERS }
  validates :status,      inclusion: { in: STATUSES }
  validates :source,      inclusion: { in: SOURCES }
  validates :period_year, presence: true,
                          numericality: { only_integer: true, greater_than: 2000, less_than: 3000 }
  validates :period_month,   numericality: { only_integer: true, in: 1..12 }, allow_nil: true
  validates :period_quarter, numericality: { only_integer: true, in: 1..4 },  allow_nil: true
  validates :received_at, presence: true

  scope :untrashed,    -> { where(trashed_at: nil) }
  scope :needs_review, -> { untrashed.where(status: "needs_review") }
  scope :filed,        -> { untrashed.where(status: "filed") }
  scope :for_period,   ->(year, month = nil) {
    rel = where(period_year: year)
    month ? rel.where(period_month: month) : rel
  }

  def needs_review? = status == "needs_review"
  def filed?        = status == "filed"
  def pending?      = status == "pending"
  def trashed?      = trashed_at.present?
end
