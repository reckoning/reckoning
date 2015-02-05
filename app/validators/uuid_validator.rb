class UuidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil? || value =~ /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    record.errors[attribute] << (options[:message] || "not a valid uuid")
  end
end
