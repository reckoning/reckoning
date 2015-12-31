Sidekiq.configure_server do |config|
  config.redis = { size: ENV["SIDEKIQ_SERVER_SIZE"] || 1 }
end

Sidekiq.configure_client do |config|
  config.redis = { size: ENV["SIDEKIQ_CLIENT_SIZE"] || 1 }
end
