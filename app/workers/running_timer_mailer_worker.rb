# frozen_string_literal: true

class RunningTimerMailerWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV["MAILER_QUEUE"] || "reckoning-mailer").to_sym

  def perform(timer_id)
    timer = Timer.find(timer_id)

    return if timer.blank?

    # rubocop:disable Rails/SkipsModelValidations
    timer.update_columns(notified: true)
    # rubocop:enable Rails/SkipsModelValidations

    TimerMailer.notify(timer).deliver_now
  end
end
