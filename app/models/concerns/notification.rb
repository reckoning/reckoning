# frozen_string_literal: true

require 'active_support/concern'

module Notification
  extend ActiveSupport::Concern
  included do
    attr_accessor :text, :notification_type, :timeout

    def to_builder
      Jbuilder.new do |notification|
        notification.text text
        notification.type notification_type
        notification.timeout timeout
      end
    end
  end
end
