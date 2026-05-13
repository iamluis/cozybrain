require "test_helper"

class WeeklyPulseJobTest < ActiveJob::TestCase
  setup do
    @user = users(:luis)
    @at   = Time.zone.local(2026, 5, 7, 9, 0, 0)
  end

  test "creates one send_notification Operation per ISO week" do
    assert_difference -> { Operation.where(kind: "send_notification").count } => 1 do
      WeeklyPulseJob.perform_now(user_id: @user.id, at: @at)
    end
  end

  test "is idempotent: running twice in the same week creates one Operation" do
    WeeklyPulseJob.perform_now(user_id: @user.id, at: @at)
    assert_no_difference -> { Operation.where(kind: "send_notification").count } do
      WeeklyPulseJob.perform_now(user_id: @user.id, at: @at)
    end
  end

  test "creates a separate Operation for a different ISO week" do
    WeeklyPulseJob.perform_now(user_id: @user.id, at: @at)
    next_week = @at + 7.days
    assert_difference -> { Operation.where(kind: "send_notification").count } => 1 do
      WeeklyPulseJob.perform_now(user_id: @user.id, at: next_week)
    end
  end

  test "the Operation input carries both text and html bodies" do
    WeeklyPulseJob.perform_now(user_id: @user.id, at: @at)
    op = Operation.where(kind: "send_notification").order(:id).last
    assert_equal @user.email_address, op.input["recipient"]
    assert op.input["subject"].include?("brain")
    assert op.input["body_text"].include?("WEEKLY PULSE")
    assert op.input["body_html"].include?("Weekly pulse")
  end
end
