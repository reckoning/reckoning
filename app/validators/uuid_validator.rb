class UuidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if nil?(value) || blank?(value) || valid?(value)
    record.errors[attribute] << (options[:message] || "not a valid uuid")
  end

  private def blank?(value)
    value.blank? && options[:allow_blank]
  end

  private def nil?(value)
    value.nil? && options[:allow_nil]
  end

  private def valid?(value)
    value =~ /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
  end
end
