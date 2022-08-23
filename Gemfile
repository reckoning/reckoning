# frozen_string_literal: true

source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

gem 'rails', '6.1.6.1'

gem 'pg', '~> 1.0'

gem 'money'
gem 'stripe'

gem 'sidekiq'
gem 'sidekiq-cron'
# for sidekiq web
gem 'sinatra', require: nil

gem 'haml'
gem 'haml-rails'
gem 'slim-rails'

gem 'devise'
gem 'devise-two-factor'
gem 'jwt'

gem 'mini_magick'
gem 'rqrcode-rails3'

gem 'cancancan'

gem 'dalli'

gem 'kaminari'
gem 'url_plumber'

gem 'jbuilder'

gem 'dynamic_fields_for_rails'

gem 'workflow', '~> 1.2.0'

gem 'sass-rails'

gem 'coffee-rails'
gem 'jquery-rails'
gem 'js-routes', '~> 1.0'
gem 'turbolinks'

gem 'bootstrap-sass'
gem 'bourbon'
gem 'font-awesome-sass', '~> 5.0'

gem 'uglifier', '>= 1.3.0'

gem 'redcarpet'

gem 'puma'

gem 'tzinfo-data'

gem 'i18n-js', '~> 3.0'
gem 'rails-i18n'

gem 'highline'
gem 'thor'

gem 'bower-rails'

gem 'roo'

gem 'rack-cors', require: 'rack/cors'

gem 'dropbox-sdk'

gem 'web_translate_it'

gem 'sentry-raven'

gem 'lograge'

gem 'typhoeus'

gem 'redis-actionpack'

# pdf rendering
gem 'wicked_pdf'

gem 'refile', require: 'refile/rails', git: 'https://github.com/refile/refile'

# heroku production
gem 'non-stupid-digest-assets'

gem 'nokogiri', '>= 1.7.1'

group :development do
  gem 'listen'
  gem 'pry-rails'

  gem 'rubocop', require: false
  gem 'rubocop-ast', require: false
  gem 'rubocop-minitest', '0.11.1', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false

  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'web-console'

  gem 'bcrypt_pbkdf', require: false
  gem 'capistrano', '~> 3.11', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-rails-console', require: false
  gem 'capistrano-rbenv', '~> 2.1', require: false
  gem 'ed25519', require: false

  gem 'letter_opener'
end

group :test do
  gem 'codeclimate-test-reporter'
  gem 'database_cleaner'
  gem 'faker'
  gem 'minitest-rails'
  gem 'mocha', require: false
  gem 'rails-perftest'
  gem 'ruby-prof'
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
  gem 'simplecov-html', require: false
  gem 'timecop'
end

group :development, :test do
  gem 'bullet'
  gem 'bundler-audit'
  gem 'byebug', platform: :mri
end
