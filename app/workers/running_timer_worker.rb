# frozen_string_literal: true

class RunningTimerWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV["TIMER_QUEUE"] || "reckoning-timer").to_sym

  def perform
    Timer.unnotified.running.find_each do |timer|
      if timer.started_at < (12.hours.ago) ||
          (timer.current_value > 12 && timer.started_at < (4.hours.ago))
        RunningTimerMailerWorker.perform_async timer.id
        ActionCable.server.broadcast "notifications_#{timer.user_id}_all", RunningTimerNotification.new.to_builder.target!
      end
    end
  end
end
