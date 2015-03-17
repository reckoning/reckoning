class TaskSerializer < BaseSerializer
  attributes :uuid, :name, :project_name

  has_many :timers, serializer: TimerSerializer

  def timers
    object.timers.where(user_id: current_user.id).order("created_at ASC")
  end
end
