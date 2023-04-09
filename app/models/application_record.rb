# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.human_enum_name(enum_name, enum_value)
    return if enum_value.blank?

    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}")
  end

  def to_jbuilder_json(*_args, api_version: "v1")
    ApplicationController.new.view_context.render(
      partial: "api/#{api_version}/#{self.class.model_name.element.pluralize}/minimal",
      locals: {
        self.class.model_name.element.to_sym => self
      },
      formats: [:json],
      handlers: [:jbuilder]
    )
  end
end
