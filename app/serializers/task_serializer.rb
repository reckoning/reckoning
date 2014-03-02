class TaskSerializer < ActiveModel::Serializer
  attributes :id, :name, :project_name, :project_id, :timers
end
