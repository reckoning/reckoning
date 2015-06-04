class AccountSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :subdomain, :created_at, :updated_at
end
