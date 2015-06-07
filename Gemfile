source 'https://rubygems.org'

ruby '2.1.5'

gem 'rails', '4.2.0'

gem 'pg'

gem 'stripe', github: 'stripe/stripe-ruby'
gem 'money'
gem 'valvat'

gem 'active_model_serializers', '~> 0.8.0'

gem 'sidekiq'
# for sidekiq web
gem 'sinatra', '>= 1.3.0', require: nil

gem 'haml'
gem 'haml-rails'
gem 'slim-rails'

gem 'devise', github: 'plataformatec/devise', branch: :master
gem 'devise-async'
gem 'devise-totp', github: 'mortik/devise-totp', branch: :master # path: 'gems/devise-totp'
gem 'cancancan'

gem 'dalli'
gem 'cache_digests'

gem 'url_plumber'
gem 'kaminari'

gem 'dynamic_fields_for_rails'

gem 'simple_states'

gem 'sass-rails'
gem 'sass'
gem 'coffee-rails'
gem 'bourbon'

gem 'bootstrap-sass'
gem 'font-awesome-sass'

gem 'jquery-rails'

gem 'asset_pipeline_routes'

gem 'uglifier'

gem 'redcarpet'

gem 'puma'

gem 'i18n-js', github: 'fnando/i18n-js', branch: :master

gem 'thor'
gem 'highline'

gem 'bower-rails'

gem 'roo'

gem 'rack-cors', require: 'rack/cors'

gem 'dropbox-sdk'

gem 'web_translate_it'

gem 'sentry-raven'

gem 'intercom-rails'

group :test do
  gem 'rails-perftest'
  gem 'minitest-rails'
  gem 'minitest-ci', git: 'git@github.com:circleci/minitest-ci.git'
  gem 'ruby-prof'
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'mocha', require: false
  gem 'spring'
  gem 'timecop'
  gem "codeclimate-test-reporter", require: nil
end

group :development, :test do
  gem 'foreman'
  gem 'rubocop', require: false
  gem 'byebug'
  gem 'guard-minitest'
  gem 'terminal-notifier-guard', '~> 1.6.1'
  gem 'mina'
end
