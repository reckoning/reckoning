class AccountSerializer < BaseSerializer
  attributes :uuid, :name, :subdomain, :created_at, :updated_at
end
