class ProjectSerializer < BaseSerializer
  attributes :uuid, :name, :name_with_customer

  has_many :tasks, serializer: TaskSerializer
end
