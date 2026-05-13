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

  # Tray action: user picks a folder for a low-confidence inbound doc. Moves
  # it to filed in that folder. Idempotent enough — we trust the caller to
  # have rendered a valid folder pill.
  def classify_into!(folder)
    raise ArgumentError, "unknown folder #{folder.inspect}" unless FOLDERS.include?(folder)
    update!(folder: folder, status: "filed", filed_at: Time.current)
  end

  # Gestoría folder-tree path for this filing. Format from brain.md:
  #     «Top»/«YYYY»/«MM-Month»/«YYYY-MM-DD»_«slug»_«amount».«ext»
  # Needs-review filings land in `_Needs Review/` regardless of folder so
  # they're visible but obviously incomplete.
  def target_path
    top    = needs_review? ? "_Needs Review" : folder.titleize
    year   = period_year.to_s
    month  = period_month ? format("%02d-%s", period_month, Date::MONTHNAMES[period_month]) : nil
    parts  = [ top, year, month, target_filename ].compact
    parts.join("/")
  end

  def target_filename
    date_str = (filable.try(:paid_on) || filable.try(:issued_on) || received_at.to_date).to_s
    slug     = target_slug
    amount   = target_amount_str
    base     = [ date_str, slug, amount ].compact.join("_")
    ext      = target_ext
    ext ? "#{base}.#{ext}" : base
  end

  private

  def target_slug
    text = filable.try(:vendor).presence ||
           filable.try(:subject).presence ||
           filable.try(:number).presence ||
           filable_type.underscore
    text.to_s.parameterize
  end

  def target_amount_str
    cents = filable.try(:amount_cents)
    return nil if cents.nil?
    "%.2f" % (cents.abs / 100.0)
  end

  def target_ext
    blob = primary_blob
    return nil unless blob
    blob.filename.extension.presence || blob.content_type.to_s.split("/").last
  end

  public

  # The blob this filing represents — receipt photo, received document file,
  # or invoice PDF. nil if no blob is attached yet.
  def primary_blob
    case filable
    when Receipt          then filable.original_photo.blob if filable.original_photo.attached?
    when ReceivedDocument then filable.original.blob       if filable.respond_to?(:original) && filable.original.attached?
    when IssuedInvoice    then filable.pdf.blob            if filable.pdf.attached?
    end
  end
end
