class TaskSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :label
  attributes :project_name, :project_label, :project_customer_name
  attributes :links

  has_many :timers, serializer: TimerSerializer

  def timers
    object.timers.where(user_id: scope.id).order("created_at ASC")
  end

  def links
    {
      project: { href: project_path(object.project_id) }
    }
  end
end
