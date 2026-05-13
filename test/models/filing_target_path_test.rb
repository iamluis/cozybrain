require "test_helper"

class FilingTargetPathTest < ActiveSupport::TestCase
  test "receipt target_path uses expenses folder + vendor slug + amount" do
    f = filings(:lab900_dinner_filing)
    # lab900_dinner: vendor "Le Pain Quotidien", €23.50, 2026-05-08, BE
    assert_equal "Expenses/2026/05-May/2026-05-08_le-pain-quotidien_23.50",
                 f.target_path
  end

  test "issued invoice target_path uses Issued/year/month + invoice number" do
    f = filings(:lab900_april_filing)
    # lab900_april: client Lab900, number 2026-0004, €8000, issued 2026-05-01
    # filing.target_slug prefers invoice.number (more specific than vendor/subject).
    assert_match %r{\AIssued/2026/04-April/2026-05-01_2026-0004_8000\.00\z},
                 f.target_path
  end

  test "needs_review filings land in _Needs Review regardless of folder" do
    f = filings(:modelo_303_filing)
    assert f.needs_review?
    assert_match %r{\A_Needs Review/2026/}, f.target_path
  end
end
