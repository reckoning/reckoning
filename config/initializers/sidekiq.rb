Sidekiq.configure_server do |config|
  config.redis = { size: 1, url: ENV["REDIS_URL"] }
end

Sidekiq.configure_client do |config|
  config.redis = { size: 7, url: ENV["REDIS_URL"] }
end
