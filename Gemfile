# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(".tool-versions").match(/ruby (.*)\n/)[1].chomp

gem "rails", "~> 7.2.2"

# Ruby 3.4 removed these from the default gemset; Rails 7.0.x still
# references them implicitly. Drop these lines after the Rails 7.1+ bump.
gem "base64"
gem "bigdecimal"
gem "csv"
gem "drb"
gem "mutex_m"

gem "pg", "~> 1.0"

gem "data_migrate"

gem "money"
gem "stripe"

gem "mobility", "~> 1.3.2"

gem "sidekiq"
gem "sidekiq-cron"
# for sidekiq web
gem "sinatra", ">= 4.2", require: nil

gem "devise"
gem "devise-two-factor"
gem "jwt"

gem "mini_magick"
gem "rqrcode"

gem "cancancan"

# Feature flags — DB-backed via Active Record. The UI mounts at
# `/flipper` for admins (see config/routes.rb).
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"

gem "kaminari"
gem "url_plumber"

gem "jbuilder"

# Modern asset pipeline. Lives alongside Sprockets during the
# frontend migration (see docs/frontend-migration-plan.md).
gem "vite_rails"

gem "dynamic_fields_for_rails"

gem "workflow", "~> 1.2.0"

gem "aasm"

gem "sass-rails"

gem "coffee-rails"
gem "jquery-rails"

gem "bootstrap-sass"
gem "bourbon"

gem "terser"

gem "redcarpet"

gem "puma"

gem "tzinfo-data"

gem "i18n-js", "~> 3.0"
gem "rails-i18n"

gem "highline"
gem "thor"

gem "bower-rails"

gem "roo"

gem "rack-cors", require: "rack/cors"

gem "sentry-rails"
gem "sentry-ruby"
gem "sentry-sidekiq"

gem "lograge"

gem "typhoeus"

# Rails has built-in `:redis_cache_store` and `ActionDispatch::Session::CacheStore`
# since 7.1; explicit `gem "redis"` is what feeds it.
gem "redis"

# connection_pool 3.0 changed its constructor (`new(opts)` removed —
# 3.x takes block-form only). Rails 7.2's RedisCacheStore still calls
# the 2.x API and boots with `ArgumentError: wrong number of arguments
# (given 1, expected 0)` against 3.x. Drop the pin after Rails 7.2
# ships connection_pool 3 support (or after the Rails 8.x bump).
gem "connection_pool", "< 3"

# pdf rendering
gem "grover"

gem "active_storage_validations"
gem "aws-sdk-s3", require: false
gem "image_processing", "~> 2.0"

gem "nokogiri", ">= 1.7.1"

gem "pry-rails"

# Speeds up rails boot via cached require paths + iseq compilation.
# Precompiled at image build time (see Dockerfile).
gem "bootsnap", require: false

group :development do
  gem "listen"

  gem "standard"

  gem "dotenv"
  gem "dotenv-rails", require: "dotenv/rails-now"

  gem "spring"
  gem "spring-watcher-listen"
  gem "web-console"

  # Deployment via Docker + Kamal (https://kamal-deploy.org).
  gem "kamal", "~> 2.11", require: false

  # Legacy Capistrano deploy — kept alongside Kamal while we cut over.
  # Drop these once `kamal deploy -d live` is the source of truth.
  gem "bcrypt_pbkdf", require: false
  gem "capistrano", "~> 3.20", require: false
  gem "capistrano-rails", "~> 1.7", require: false
  gem "capistrano-rails-console", require: false
  gem "capistrano-rbenv", "~> 2.1", require: false
  gem "ed25519", require: false

  gem "letter_opener"
end

group :test do
  gem "database_cleaner"
  gem "faker"
  gem "minitest-rails"
  gem "mocha", require: false
  gem "rails-perftest"
  gem "ruby-prof"
  gem "simplecov", require: false
  gem "simplecov-console", require: false
  gem "simplecov-html", require: false
  gem "timecop"
end

group :development, :test do
  gem "brakeman", require: false
  gem "bullet"
  gem "bundler-audit"
  gem "byebug", platform: :mri

  gem "knapsack"

  # Bridges the Playwright e2e suite to Rails-side helpers
  # (DB clean, scenario seeding, eval). See
  # `test/e2e/app_commands/` for the registered commands and
  # `test/e2e/support/on-rails.ts` for the JS client.
  gem "cypress-on-rails"
end
