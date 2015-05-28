class ProjectSerializer < BaseSerializer
  attributes :uuid, :name, :name_with_customer

  has_many :tasks, serializer: TaskSerializer

  def tasks
    object.tasks.includes(:timers).order("timers.created_at DESC")
  end
end
