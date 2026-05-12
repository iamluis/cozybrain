require "test_helper"

class ReceivedDocumentTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    ReceivedDocument.all.each { |d| assert d.valid?, d.errors.full_messages.to_s }
  end

  test "kind must be in KINDS" do
    d = received_documents(:ryanair_invoice).dup
    d.kind = "nonsense"
    assert_not d.valid?
  end

  test "filing reflects email source for emailed docs" do
    assert_equal "email", received_documents(:ryanair_invoice).filing.source
  end
end
