require "test_helper"

class TrayControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:luis)) }

  test "POST /tray/inbound_docs/:filing_id/classify moves filing to chosen folder + filed" do
    filing = filings(:modelo_303_filing)
    assert_equal "needs_review", filing.status

    post tray_classify_path(filing_id: filing.id), params: { folder: "tax" }

    filing.reload
    assert_equal "tax",   filing.folder
    assert_equal "filed", filing.status
    assert filing.filed_at.present?
    assert_redirected_to home_path
  end

  test "rejects an unknown folder" do
    filing = filings(:modelo_303_filing)
    assert_raises(ArgumentError) do
      post tray_classify_path(filing_id: filing.id), params: { folder: "garbage" }
    end
  end
end
