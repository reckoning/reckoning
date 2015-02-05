class AccountSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :subdomain, :created_at, :updated_at

  def uuid
    object.id.to_s
  end
end
