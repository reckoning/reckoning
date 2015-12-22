source 'https://rubygems.org'

ruby '2.2.4'

gem 'rails', '4.2.5'

gem 'pg'

gem 'stripe', github: 'stripe/stripe-ruby'
gem 'money'
gem 'valvat'

gem 'active_model_serializers'

gem 'sidekiq'
# for sidekiq web
gem 'sinatra', '>= 1.3.0', require: nil

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

gem 'dynamic_fields_for_rails'

gem 'workflow'

gem 'sass-rails'
gem 'coffee-rails'
gem 'bourbon'

gem 'bootstrap-sass'
gem 'font-awesome-sass'

gem 'jquery-rails'

gem 'js-routes'

gem 'uglifier'

gem 'redcarpet'

gem 'puma'

gem "i18n-js", ">= 3.0.0.rc11"
gem 'rails-i18n', '~> 4.0.0'

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

# heroku production
gem 'rails_12factor', group: :production
gem 'non-stupid-digest-assets'

gem 'pry-rails', group: :development

group :test do
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
  gem 'rubocop', require: false

  # generate fake data
  gem 'faker'

  # debugging
  gem 'bullet'
  gem 'byebug'
  gem 'web-console', '~> 2.0'
  gem 'spring'
end
