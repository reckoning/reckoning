# config/mocha.rb
if Rails.env.test? || Rails.env.development?
  require "mocha/version"
  require "mocha/deprecation"
  Mocha::Deprecation.mode = :disabled
end
