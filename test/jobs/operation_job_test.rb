require "test_helper"

class OperationJobTest < ActiveJob::TestCase
  test "perform dispatches the operation and marks it succeeded" do
    op = Operation.create!(
      kind: "send_notification",
      adapter_name: Adapter::Null::Notifier.name,
      input: { "recipient" => "x@x", "subject" => "S", "body_text" => "T" },
      max_attempts: 3
    )

    OperationJob.perform_now(op.id)

    op.reload
    assert_equal "succeeded", op.status
    assert_equal 1, op.attempt_count
  end
end
