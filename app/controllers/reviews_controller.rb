class ReviewsController < ApplicationController
  layout "app"

  def show
    @needs_review_filings   = Filing.needs_review
    @unmatched_transactions = BankTransaction.unmatched
  end
end
