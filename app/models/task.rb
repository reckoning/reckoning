class Task < ActiveRecord::Base
  validates_presence_of :project_id, :name

  belongs_to :project
  belongs_to :user
  has_many :timers, dependent: :destroy
  has_and_belongs_to_many :weeks

  def project_name
    return project.name_with_customer
  end

  def timer_values
    values = 0.0
    timers.each do |timer|
      values += timer.value.to_d
    end
    values
  end
end
