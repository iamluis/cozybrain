require "test_helper"

class FilingTest < ActiveSupport::TestCase
  test "fixtures load with valid filings" do
    Filing.all.each { |f| assert f.valid?, "#{f.filable_type}##{f.id} invalid: #{f.errors.full_messages}" }
  end

  test "needs_review scope returns only untrashed needs_review filings" do
    filings = Filing.needs_review
    assert_includes filings, filings(:modelo_303_filing)
    assert_not_includes filings, filings(:lab900_dinner_filing)
  end

  test "for_period filters by year and optional month" do
    may_2026 = Filing.for_period(2026, 5)
    assert_includes may_2026, filings(:lab900_dinner_filing)
    assert_not_includes may_2026, filings(:lab900_april_filing)
  end

  test "trashed filings are excluded from untrashed scope" do
    f = filings(:lab900_dinner_filing)
    f.update!(trashed_at: Time.current)
    assert_not_includes Filing.untrashed, f
  end

  test "folder must be in allowlist" do
    f = filings(:lab900_dinner_filing).dup
    f.folder = "junk"
    assert_not f.valid?
    assert_includes f.errors[:folder], "is not included in the list"
  end

  test "filable polymorphism resolves to correct class" do
    assert_kind_of Receipt,          filings(:lab900_dinner_filing).filable
    assert_kind_of ReceivedDocument, filings(:ryanair_filing).filable
    assert_kind_of IssuedInvoice,    filings(:lab900_april_filing).filable
  end
end
