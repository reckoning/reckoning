# encoding: utf-8
# frozen_string_literal: true

module ResourceHelper
  def resource_message(resource, action, state)
    I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t(:"resources.#{resource}"))
  end
end
