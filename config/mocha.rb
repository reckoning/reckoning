# encoding: utf-8
# frozen_string_literal: true
# config/mocha.rb
if Rails.env.test? || Rails.env.development?
  require "mocha/version"
  require "mocha/deprecation"
  Mocha::Deprecation.mode = :disabled
end
