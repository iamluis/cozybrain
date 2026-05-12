# Runtime::Dispatcher is the boundary between the app and the outside world.
# It:
#
#   - holds the port → adapter binding registry
#   - resolves a persistent Operation to its adapter
#   - asserts that the Operation's recorded adapter_name still matches the
#     live binding (catches binding changes after enqueue)
#   - asserts input shape before begin!
#   - drives the Operation state machine: begin! → succeed!/fail!
#   - asserts output shape on success
#   - re-raises on retryable failure (so the wrapping job retries),
#     swallows on terminal abort (so the job stops cleanly)
#
# Pairs every assertion across two code paths: once here at the boundary,
# once inside Adapter::Base#call (which also asserts shapes via the port).
module Runtime
  module Dispatcher
    KIND_TO_PORT = {
      "certify_receipt"          => Port::ReceiptCertifier,
      "send_notification"        => Port::Notifier
      # Future kinds bind their ports as those milestones ship:
      #   "issue_invoice"            => Port::InvoiceIssuer        (0008)
      #   "deliver_inbound_document" => Port::InboundDocumentReceiver (0009)
      #   "sync_folder"              => Port::FolderSync           (0010)
      #   "sync_bank_transactions"   => Port::BankSync             (0013)
    }.freeze

    @bindings = {}
    @mutex    = Mutex.new

    module_function

    def bind(port:, adapter:)
      Runtime::Assert.invariant!(port.respond_to?(:assert_input!),  "bind: port must define .assert_input!")
      Runtime::Assert.invariant!(port.respond_to?(:assert_output!), "bind: port must define .assert_output!")
      Runtime::Assert.invariant!(adapter.respond_to?(:call),        "bind: adapter must define .call")
      Runtime::Assert.invariant!(adapter.respond_to?(:port_module), "bind: adapter must define .port_module")
      Runtime::Assert.invariant!(adapter.port_module == port,       "bind: adapter.port_module #{adapter.port_module} != port #{port}")

      @mutex.synchronize { @bindings[port] = adapter }
    end

    def adapter_for(port)
      @mutex.synchronize do
        @bindings.fetch(port) do
          raise AssertionError, "no adapter bound for port #{port}"
        end
      end
    end

    def reset_bindings!
      @mutex.synchronize { @bindings = {} }
    end

    def call(operation)
      assert_operation!(operation)

      port    = KIND_TO_PORT.fetch(operation.kind)
      adapter = adapter_for(port)
      Runtime::Assert.invariant!(operation.adapter_name == adapter.name,
        "Dispatcher: operation.adapter_name #{operation.adapter_name.inspect} != bound adapter #{adapter.name.inspect}")

      # Pre-boundary input check (Adapter::Base will re-check internally).
      port.assert_input!(operation.input)

      operation.begin!
      output = nil
      begin
        output = adapter.call(operation.input.deep_dup)
      rescue StandardError => e
        operation.fail!(error_message: "#{e.class}: #{e.message}")
        raise e unless operation.status == "aborted"
        return operation
      end

      # Post-boundary output check (Adapter::Base already asserted; paired).
      port.assert_output!(output)
      operation.succeed!(output: output)
      operation
    end

    def assert_operation!(operation)
      Runtime::Assert.invariant!(operation.is_a?(Operation),
        "Dispatcher: expected Operation, got #{operation.class}")
      Runtime::Assert.invariant!(operation.persisted?,
        "Dispatcher: Operation must be persisted before dispatch")
      Runtime::Assert.invariant!(KIND_TO_PORT.key?(operation.kind),
        "Dispatcher: no port bound for kind #{operation.kind.inspect}")
    end
  end
end
