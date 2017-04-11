# encoding: utf-8
# frozen_string_literal: true
class RunningTimerWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['TIMER_QUEUE'] || 'reckoning-timer').to_sym

  def perform
    Timer.unnotified.running.find_each do |timer|
      if timer.started_at < (Time.zone.now - 12.hours) ||
         (timer.current_value > 12 && timer.started_at < (Time.zone.now - 4.hours))
        RunningTimerMailerWorker.perform_async timer.id
        ActionCable.server.broadcast "notifications_#{current_user.id}_all", RunningTimerNotification.new.to_builder.target!
      end
    end
  end
end
