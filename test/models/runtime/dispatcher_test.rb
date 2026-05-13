require "test_helper"

class Runtime::DispatcherTest < ActiveSupport::TestCase
  # Test-only adapters bound to Port::Notifier so we can exercise the
  # dispatcher's happy path, failure → retry, and failure → abort branches
  # without depending on the production Null adapter's behaviour.

  class SuccessNotifier < Adapter::Base
    class << self
      def port_module = Port::Notifier
      def _perform(_input)
        {
          "delivered_at"        => Time.current.iso8601,
          "provider_message_id" => "test-success"
        }
      end
    end
  end

  class RaisingNotifier < Adapter::Base
    class << self
      def port_module = Port::Notifier
      def _perform(_input)
        raise "intentional failure for dispatcher test"
      end
    end
  end

  def valid_input
    { "recipient" => "x@example.com", "subject" => "S", "body_text" => "T", "body_html" => "<p>T</p>" }
  end

  def make_operation(adapter:, max_attempts: 3, attempt_count: 0, status: "pending")
    op = Operation.create!(
      kind: "send_notification",
      adapter_name: adapter.name,
      status: status,
      attempt_count: attempt_count,
      max_attempts: max_attempts,
      input: valid_input
    )
    op
  end

  setup do
    Runtime::Dispatcher.reset_bindings!
  end

  teardown do
    Runtime::Dispatcher.reset_bindings!
    Runtime::Dispatcher.bind_defaults!
  end

  test "happy path: pending → running → succeeded, output recorded" do
    Runtime::Dispatcher.bind(port: Port::Notifier, adapter: SuccessNotifier)
    op = make_operation(adapter: SuccessNotifier)

    Runtime::Dispatcher.call(op)

    op.reload
    assert_equal "succeeded", op.status
    assert_equal 1, op.attempt_count
    assert_equal "test-success", op.output["provider_message_id"]
  end

  test "adapter mismatch (operation.adapter_name != bound) raises AssertionError" do
    Runtime::Dispatcher.bind(port: Port::Notifier, adapter: SuccessNotifier)
    op = make_operation(adapter: RaisingNotifier) # mismatch with bound

    assert_raises(Runtime::AssertionError) { Runtime::Dispatcher.call(op) }
  end

  test "no binding for the port raises AssertionError" do
    # No bind call at all for Port::Notifier (setup reset bindings).
    op = make_operation(adapter: SuccessNotifier)

    assert_raises(Runtime::AssertionError) { Runtime::Dispatcher.call(op) }
  end

  test "failure with attempts remaining transitions to failed and re-raises" do
    Runtime::Dispatcher.bind(port: Port::Notifier, adapter: RaisingNotifier)
    op = make_operation(adapter: RaisingNotifier, max_attempts: 3)

    assert_raises(RuntimeError) { Runtime::Dispatcher.call(op) }

    op.reload
    assert_equal "failed", op.status
    assert_equal 1, op.attempt_count
    assert_match(/intentional failure/, op.error)
  end

  test "failure on final attempt transitions to aborted and does NOT re-raise" do
    Runtime::Dispatcher.bind(port: Port::Notifier, adapter: RaisingNotifier)
    op = make_operation(adapter: RaisingNotifier, max_attempts: 2, attempt_count: 1, status: "failed")

    # Should NOT raise — terminal abort is handled cleanly.
    Runtime::Dispatcher.call(op)

    op.reload
    assert_equal "aborted", op.status
    assert op.terminal?
  end

  test "rejects non-persisted Operation" do
    Runtime::Dispatcher.bind(port: Port::Notifier, adapter: SuccessNotifier)
    op = Operation.new(
      kind: "send_notification", adapter_name: SuccessNotifier.name,
      input: valid_input, max_attempts: 5
    )
    assert_raises(Runtime::AssertionError) { Runtime::Dispatcher.call(op) }
  end

  test "rejects operation with invalid input shape" do
    Runtime::Dispatcher.bind(port: Port::Notifier, adapter: SuccessNotifier)
    op = Operation.create!(
      kind: "send_notification",
      adapter_name: SuccessNotifier.name,
      input: { "recipient" => "x" }, # missing subject + body_text
      max_attempts: 3
    )
    assert_raises(Runtime::AssertionError) { Runtime::Dispatcher.call(op) }
  end

  test "bind/0 refuses adapter whose port_module does not match" do
    err = assert_raises(Runtime::AssertionError) do
      Runtime::Dispatcher.bind(port: Port::ReceiptCertifier, adapter: SuccessNotifier)
    end
    assert_match(/port_module/, err.message)
  end
end
