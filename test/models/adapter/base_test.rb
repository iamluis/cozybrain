require "test_helper"

class Adapter::BaseTest < ActiveSupport::TestCase
  test "Null::ReceiptCertifier returns output matching port shape" do
    output = Adapter::Null::ReceiptCertifier.call("receipt_id" => 1, "photo_url" => "data:img,abc")
    assert output["certified_pdf_url"].is_a?(String)
    assert output["provider_ref"].is_a?(String)
  end

  test "Null::Notifier returns output matching port shape" do
    output = Adapter::Null::Notifier.call("recipient" => "x@x", "subject" => "s", "body_text" => "t", "body_html" => "<p>t</p>")
    assert output["delivered_at"].is_a?(String)
    assert output["provider_message_id"].is_a?(String)
  end

  test "Base.call asserts input is a Hash" do
    assert_raises(Runtime::AssertionError) do
      Adapter::Null::Notifier.call("not a hash")
    end
  end

  test "Base.call enforces port input shape" do
    assert_raises(Runtime::AssertionError) do
      Adapter::Null::Notifier.call("recipient" => "x@x") # missing subject + body_text
    end
  end

  test "subclass without port_module raises NotImplementedError" do
    bare = Class.new(Adapter::Base)
    assert_raises(NotImplementedError) { bare.call({ "any" => "thing" }) }
  end
end
