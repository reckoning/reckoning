# frozen_string_literal: true

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if nil?(value) || blank?(value) || valid?(value)

    record.errors.add(attribute, (options[:message] || "not a valid email"))
  end

  private def blank?(value)
    value.blank? && options[:allow_blank]
  end

  private def nil?(value)
    value.nil? && options[:allow_nil]
  end

  private def valid?(value)
    value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  end
end
