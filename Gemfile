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
gem "sinatra", require: nil

gem "haml"
gem "haml-rails"
gem "slim-rails"

gem "devise"
gem "devise-two-factor"
gem "jwt"

gem "mini_magick"
gem "rqrcode"

gem "cancancan"

gem "dalli"

gem "kaminari"
gem "url_plumber"

gem "jbuilder"

gem "dynamic_fields_for_rails"

gem "workflow", "~> 1.2.0"

gem "aasm"

gem "sass-rails"

gem "coffee-rails"
gem "jquery-rails"
gem "turbolinks"

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

gem "redis-actionpack"
gem "redis-store"

# pdf rendering
gem "grover"

gem "active_storage_validations"
gem "aws-sdk-s3", require: false
gem "image_processing", "~> 1.2"

gem "nokogiri", ">= 1.7.1"

gem "pry-rails"

group :development do
  gem "listen"

  gem "standard"

  gem "dotenv"
  gem "dotenv-rails", require: "dotenv/rails-now"

  gem "spring"
  gem "spring-watcher-listen"
  gem "web-console"

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
end
