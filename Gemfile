# encoding: utf-8
# frozen_string_literal: true
source 'https://rubygems.org'

ruby '2.3.1'

gem 'rails', '5.0.0'

gem 'pg'

gem 'money'
gem 'stripe', github: 'stripe/stripe-ruby'
gem 'valvat'

gem 'sidekiq'
# for sidekiq web
gem 'rack-protection', github: 'sinatra/rack-protection'
gem 'sinatra', require: nil, github: 'sinatra/sinatra'

gem 'haml'
gem 'haml-rails'
gem 'slim-rails'

gem 'devise'
gem 'devise-two-factor'

gem 'mini_magick'
gem 'rqrcode-rails3'

gem 'cancancan'

gem 'dalli'

gem 'kaminari'
gem 'url_plumber'

gem 'jbuilder', '~> 2.5'

gem 'dynamic_fields_for_rails'

gem 'workflow'

gem 'sass-rails', '~> 5.0'

gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'js-routes'
gem 'turbolinks', '~> 5'

gem 'bootstrap-sass'
gem 'bourbon'
gem 'font-awesome-sass'

gem 'uglifier', '>= 1.3.0'

gem 'redcarpet'

gem 'puma', '~> 3.0'

gem "i18n-js", ">= 3.0.0.rc11"
gem 'rails-i18n'

gem 'highline'
gem 'thor'

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

gem "refile", require: 'refile/rails', github: 'refile/refile'
gem "refile-s3"

# heroku production
gem 'non-stupid-digest-assets'

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'pry-rails'
  gem 'rubocop', require: false
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console'

  # deployment
  gem 'mina', require: false
  gem 'mina-multistage', require: false
end

group :test do
  gem "codeclimate-test-reporter", require: false
  gem 'coveralls', require: false
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'faker'
  gem 'minitest-rails'
  gem 'mocha', require: false
  gem 'rails-perftest', github: 'rails/rails-perftest'
  gem 'ruby-prof'
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
  gem 'simplecov-html', require: false
  gem 'timecop'
end

group :development, :test do
  gem 'bullet'
  gem 'byebug', platform: :mri
end
