class BaseSerializer < ActiveModel::Serializer
  def attributes
    super.map { |k, v| [k.to_s.camelize(:lower).to_sym, v] }.to_h
  end

  def associations
    super.map { |k, v| [k.to_s.camelize(:lower).to_sym, v] }.to_h
  end

  def uuid
    object.id
  end
end
