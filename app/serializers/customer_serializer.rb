class CustomerSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :created_at, :updated_at
end
