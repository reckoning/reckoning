class ValidationErrorSerializer < BaseSerializer
  attributes :code, :message
  has_many :errors
end
