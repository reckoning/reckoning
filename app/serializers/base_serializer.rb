class BaseSerializer < ActiveModel::Serializer
  def attributes
    super.map { |k, v| [k.to_s.camelize(:lower).to_sym, v] }.to_h
  end

  def self.has_many(*args)
    super(*camelize_keys(args))
  end

  def self.has_one(*args)
    super(*camelize_keys(args))
  end

  def self.camelize_keys(args)
    options = args.extract_options!
    options.reverse_merge!(key: args.first.to_s.camelize(:lower).to_sym)
    args << options
    args
  end
end
