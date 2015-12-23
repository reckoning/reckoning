class Task < ActiveRecord::Base
  belongs_to :project
  has_many :timers, dependent: :destroy

  validates :project, :name, presence: true

  delegate :name, :label, :customer_name, to: :project, prefix: true

  def label
    "#{name} (#{I18n.t("labels.task.billable.#{billable}")})"
  end

  def timer_values
    values = 0.0
    timers.each do |timer|
      values += timer.value.to_d
    end
    values
  end
end
