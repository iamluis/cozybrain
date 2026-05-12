# Operation is the persistent record of an intent to call an external service
# through the integration spine. Each Operation tracks its own status
# (pending → running → succeeded | failed | aborted), attempt count, the
# adapter it's bound to, the inputs frozen at enqueue, and the output or
# error from the most recent run.
#
# State transitions are bang methods (begin!, succeed!, fail!) that assert
# the current status before mutating. Illegal transitions raise
# Runtime::AssertionError — they're programmer errors, not domain errors.
class Operation < ApplicationRecord
  # The kinds of work the spine knows about. Each kind maps to exactly one
  # Port at dispatch time (see Runtime::Dispatcher::KIND_TO_PORT).
  KINDS = %w[
    certify_receipt
    issue_invoice
    send_notification
    sync_bank_transactions
    deliver_inbound_document
    sync_folder
  ].freeze

  # pending  → not yet run; eligible for begin!
  # running  → adapter executing; only succeed! or fail! valid next
  # succeeded → terminal; result in #output
  # failed   → adapter raised but retries remain; eligible for begin!
  # aborted  → terminal; max_attempts exhausted; result in #error
  STATUSES          = %w[ pending running succeeded failed aborted ].freeze
  RUNNABLE_STATUSES = %w[ pending failed ].freeze
  TERMINAL_STATUSES = %w[ succeeded aborted ].freeze

  validates :kind,          inclusion: { in: KINDS }
  validates :status,        inclusion: { in: STATUSES }
  validates :attempt_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :max_attempts,  numericality: { only_integer: true, greater_than: 0 }
  validates :adapter_name,  presence: true

  scope :runnable, -> { where(status: RUNNABLE_STATUSES).where("attempt_count < max_attempts") }
  scope :terminal, -> { where(status: TERMINAL_STATUSES) }

  def runnable?
    RUNNABLE_STATUSES.include?(status) && attempt_count < max_attempts
  end

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  def begin!
    assert_status_in!(RUNNABLE_STATUSES, action: "begin!")
    Runtime::Assert.invariant!(attempt_count < max_attempts,
      "Operation##{id}.begin!: attempt_count #{attempt_count} >= max_attempts #{max_attempts}")

    update!(
      status: "running",
      attempt_count: attempt_count + 1,
      started_at: Time.current,
      error: nil
    )
  end

  def succeed!(output:)
    assert_status_in!(%w[ running ], action: "succeed!")
    Runtime::Assert.invariant!(output.is_a?(Hash), "Operation##{id}.succeed!: output must be a Hash, got #{output.class}")

    update!(
      status: "succeeded",
      output: output.deep_stringify_keys,
      completed_at: Time.current
    )
  end

  def fail!(error_message:)
    assert_status_in!(%w[ running ], action: "fail!")

    next_status = attempt_count >= max_attempts ? "aborted" : "failed"
    update!(
      status: next_status,
      error: error_message.to_s.truncate(1000),
      completed_at: Time.current
    )
  end

  private

  def assert_status_in!(allowed, action:)
    return if allowed.include?(status)
    raise Runtime::AssertionError,
      "Operation##{id || '?'}.#{action}: current status #{status.inspect}; allowed #{allowed.inspect}"
  end
end
