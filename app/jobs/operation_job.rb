# OperationJob is the Solid Queue worker entry point for the integration
# spine. It does almost nothing: load the Operation, hand it to the
# Dispatcher. The Dispatcher owns assertion and state transitions.
#
# Re-raise / retry semantics: the Dispatcher re-raises on retryable
# failure (status: failed) and swallows on terminal abort (status:
# aborted). The retry_on attempts cap is intentionally higher than any
# realistic Operation.max_attempts — Operation is the real bound, this
# just keeps ActiveJob from giving up early.
class OperationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 20

  def perform(operation_id)
    operation = Operation.find(operation_id)
    Runtime::Dispatcher.call(operation)
  end
end
