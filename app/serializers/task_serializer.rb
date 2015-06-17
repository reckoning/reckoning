class TaskSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :project_name

  has_many :timers, serializer: TimerSerializer

  def timers
    object.timers.where(user_id: scope.id).order("created_at ASC")
  end
end
