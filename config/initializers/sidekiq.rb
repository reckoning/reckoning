# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

sidekiq_config = { url: ENV.fetch('REDIS_URL', nil), db: ENV['REDIS_DB'] || 0 }

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config

  schedule_file = 'config/schedule.yml'

  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file) if File.exist?(schedule_file)
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end
