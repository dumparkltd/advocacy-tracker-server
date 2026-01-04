require "sidekiq"
require "sidekiq/api"

redis_config = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/5"),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
}

Sidekiq.configure_server do |config|
  config.redis = redis_config.merge(size: 12)
  config[:queues] = %w[default]
end

Sidekiq.configure_client do |config|
  config.redis = redis_config.merge(size: 1)
end
