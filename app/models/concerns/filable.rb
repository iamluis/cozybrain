module Filable
  extend ActiveSupport::Concern

  included do
    has_one :filing, as: :filable, dependent: :destroy, autosave: true, inverse_of: :filable
    validates :filing, presence: true
  end

  def filing
    super || build_filing
  end
end
