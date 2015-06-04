class UserSerializer < ActiveModel::Serializer
  attributes :uuid, :email, :name, :authentication_token, :created_at, :updated_at

  def uuid
    object.id.to_s
  end
end
