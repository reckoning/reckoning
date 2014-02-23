class TimerSerializer < ActiveModel::Serializer
  attributes :id, :date, :value, :task_id
end
