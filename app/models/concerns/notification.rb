# frozen_string_literal: true

require "active_support/concern"

module Notification
  extend ActiveSupport::Concern
  included do
    attr_accessor :text, :notification_type, :timeout

    def to_json(*_args)
      to_jbuilder_json
    end
  end
end
