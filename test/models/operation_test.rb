require "test_helper"

class OperationTest < ActiveSupport::TestCase
  test "fixtures load with valid records" do
    Operation.all.each { |op| assert op.valid?, op.errors.full_messages.to_s }
  end

  test "validates kind against KINDS allowlist" do
    op = operations(:pending_certify).dup
    op.kind = "nonsense"
    assert_not op.valid?
    assert_includes op.errors[:kind], "is not included in the list"
  end

  test "validates status against STATUSES allowlist" do
    op = operations(:pending_certify).dup
    op.status = "weird"
    assert_not op.valid?
  end

  test "max_attempts must be positive" do
    op = operations(:pending_certify).dup
    op.max_attempts = 0
    assert_not op.valid?
  end

  test "runnable scope excludes terminal and exhausted operations" do
    op = operations(:pending_certify)
    assert_includes Operation.runnable, op

    op.update!(status: "succeeded", completed_at: Time.current)
    refute_includes Operation.runnable, op
  end

  test "begin! transitions pending → running and bumps attempt_count" do
    op = operations(:pending_certify)
    assert_changes -> { op.attempt_count }, from: 0, to: 1 do
      op.begin!
    end
    assert_equal "running", op.status
    assert op.started_at.present?
  end

  test "begin! allowed from failed status (retry)" do
    op = operations(:pending_certify)
    op.update_columns(status: "failed", attempt_count: 1, completed_at: Time.current)
    op.begin!
    assert_equal "running", op.reload.status
    assert_equal 2, op.attempt_count
  end

  test "begin! from running raises AssertionError" do
    op = operations(:pending_certify)
    op.update_columns(status: "running", attempt_count: 1, started_at: Time.current)
    assert_raises(Runtime::AssertionError) { op.begin! }
  end

  test "begin! refuses when attempt_count already at max_attempts" do
    op = operations(:pending_certify)
    op.update_columns(attempt_count: op.max_attempts, status: "failed")
    assert_raises(Runtime::AssertionError) { op.begin! }
  end

  test "succeed! requires running status" do
    op = operations(:pending_certify)
    assert_raises(Runtime::AssertionError) do
      op.succeed!(output: { "x" => "y" })
    end
  end

  test "succeed! records output and timestamp" do
    op = operations(:pending_certify)
    op.begin!
    op.succeed!(output: { "ok" => true })
    assert_equal "succeeded", op.reload.status
    assert op.completed_at.present?
    assert_equal({ "ok" => true }, op.output)
  end

  test "succeed! requires Hash output" do
    op = operations(:pending_certify)
    op.begin!
    assert_raises(Runtime::AssertionError) do
      op.succeed!(output: "not a hash")
    end
  end

  test "fail! transitions to failed when attempts remain" do
    op = operations(:pending_certify)
    op.begin!
    op.fail!(error_message: "boom")
    assert_equal "failed", op.reload.status
    assert_equal "boom", op.error
  end

  test "fail! transitions to aborted when attempts exhausted" do
    op = operations(:pending_certify)
    op.update_columns(attempt_count: op.max_attempts - 1, status: "failed")
    op.begin!  # now attempt_count == max_attempts
    op.fail!(error_message: "final failure")
    assert_equal "aborted", op.reload.status
    assert op.terminal?
  end

  test "fail! truncates long error messages" do
    op = operations(:pending_certify)
    op.begin!
    op.fail!(error_message: "x" * 2000)
    assert_equal 1000, op.reload.error.length
  end

  test "terminal? reflects succeeded and aborted statuses" do
    assert operations(:succeeded_notification).terminal?
    refute operations(:pending_certify).terminal?
  end
end
