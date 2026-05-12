class ReceivedDocument < ApplicationRecord
  include Filable

  KINDS = %w[ email_invoice bank_statement tax_doc corporate other ].freeze

  has_one_attached :original

  validates :kind, inclusion: { in: KINDS }
end
