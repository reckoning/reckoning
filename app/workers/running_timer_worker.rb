# encoding: utf-8
# frozen_string_literal: true
class RunningTimerWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['TIMER_QUEUE'] || 'reckoning-timer').to_sym

  def perform
    Timer.running.find_each do |timer|
      if timer.started_at < (Time.zone.now - 12.hours)
        RunningTimerMailerWorker.perform_async timer.id
      end
    end
  end
end
