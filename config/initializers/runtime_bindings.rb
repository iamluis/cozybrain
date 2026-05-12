# Default port → adapter bindings for the integration spine.
#
# Defaults are Null adapters (synthetic output, no I/O). Real provider
# adapters (Holded etc., milestone 0013) override these by editing
# Runtime::Dispatcher.bind_defaults!.

Rails.application.config.to_prepare do
  Runtime::Dispatcher.bind_defaults!
end
