# Composes the weekly pulse for the current ISO week, renders the HTML +
# text bodies, and enqueues a send_notification Operation via the spine.
# Idempotent: at most one Operation per (user, ISO year-week) pair.
#
# Wired to recurring schedule (Solid Queue) in config/recurring.yml —
# Monday 08:00 Europe/Madrid.
class WeeklyPulseJob < ApplicationJob
  queue_as :default

  def perform(user_id: nil, at: Time.current)
    user = user_id ? User.find(user_id) : User.first
    return if user.nil?

    pulse = WeeklyPulse.new(at: at)
    correlation_id = correlation_id_for(user, pulse)

    return if Operation.exists?(correlation_id: correlation_id)

    operation = Operation.create!(
      kind:           "send_notification",
      adapter_name:   Runtime::Dispatcher.adapter_for(Port::Notifier).name,
      correlation_id: correlation_id,
      max_attempts:   5,
      input: {
        "recipient" => user.email_address,
        "subject"   => "brain — #{pulse.period_label}",
        "body_text" => render_text(pulse),
        "body_html" => render_html(pulse)
      }
    )

    OperationJob.perform_later(operation.id)
  end

  private

  def correlation_id_for(user, pulse)
    iso_year, iso_week = pulse.week_start.strftime("%G"), pulse.week_start.strftime("%V")
    "weekly_pulse:#{user.id}:#{iso_year}-#{iso_week}"
  end

  def render_text(pulse)
    ApplicationController.render(
      template: "weekly_pulses/show",
      formats:  [ :text ],
      layout:   false,
      assigns:  { pulse: pulse }
    )
  end

  def render_html(pulse)
    ApplicationController.render(
      template: "weekly_pulses/show",
      formats:  [ :html ],
      layout:   false,
      assigns:  { pulse: pulse }
    )
  end
end
