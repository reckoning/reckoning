class ValidationErrorSerializer < ActiveModel::Serializer
  attributes :code, :message
  has_many :errors
end
