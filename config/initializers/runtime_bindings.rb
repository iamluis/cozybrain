# Default port → adapter bindings for the integration spine.
#
# Every Port gets a binding here. The default is the Null adapter
# (synthetic output, no I/O). Real provider adapters override these as
# their milestones ship — e.g., milestone 0013 will replace the Null
# bindings for ReceiptCertifier / InvoiceIssuer / BankSync with their
# Holded equivalents.

Rails.application.config.to_prepare do
  Runtime::Dispatcher.bind(port: Port::ReceiptCertifier, adapter: Adapter::Null::ReceiptCertifier)
  Runtime::Dispatcher.bind(port: Port::Notifier,         adapter: Adapter::Null::Notifier)
end
