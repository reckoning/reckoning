Sidekiq.configure_server do |config|
  config.redis = { size: 4 }
end

Sidekiq.configure_client do |config|
  config.redis = { size: 6 }
end
