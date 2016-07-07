# encoding: utf-8
# frozen_string_literal: true
source 'https://rubygems.org'

ruby '2.3.1'

gem 'rails', '4.2.6'

gem 'pg'

gem 'stripe', github: 'stripe/stripe-ruby'
gem 'money'
gem 'valvat'

gem 'sidekiq'
# for sidekiq web
gem 'sinatra', require: nil

gem 'haml'
gem 'haml-rails'
gem 'slim-rails'

gem 'devise'
gem 'devise-two-factor'

gem 'rqrcode-rails3'
gem 'mini_magick'
gem 'cancancan'

gem 'dalli'

gem 'url_plumber'
gem 'kaminari'

gem 'jbuilder', '~> 2.5'

gem 'dynamic_fields_for_rails'

gem 'workflow'

gem 'sass-rails', '~> 5.0'

gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
gem 'js-routes'

gem 'bourbon'
gem 'bootstrap-sass'
gem 'font-awesome-sass'

gem 'uglifier', '>= 1.3.0'

gem 'redcarpet'

gem 'puma', '~> 3.0'

gem "i18n-js", ">= 3.0.0.rc11"
gem 'rails-i18n'

gem 'thor'
gem 'highline'

gem 'bower-rails'

gem 'roo'

gem 'rack-cors', require: 'rack/cors'

gem 'dropbox-sdk'

gem 'web_translate_it'

gem 'sentry-raven'

gem 'typhoeus'

# pdf rendering
gem 'wicked_pdf'
gem 'wkhtmltopdf-heroku'

gem "refile", require: 'refile/rails'
gem "refile-s3"

# heroku production
gem 'rails_12factor', group: :production
gem 'non-stupid-digest-assets'

group :development do
  gem 'pry-rails'
  gem 'rubocop', require: false
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'faker'
  gem 'coveralls', require: false
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
  gem 'simplecov-html', require: false
  gem 'rails-perftest'
  gem 'minitest-rails'
  gem 'ruby-prof'
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'mocha', require: false
  gem 'timecop'
  gem "codeclimate-test-reporter", require: false
end

group :development, :test do
  gem 'bullet'
  gem 'byebug', platform: :mri
  gem 'jasmine-rails'
end
