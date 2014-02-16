class Task < ActiveRecord::Base
  validates_presence_of :project_id, :name

  belongs_to :project
  has_many :timers, dependent: :destroy
  has_and_belongs_to_many :weeks

  def timer_values
    values = 0.0
    timers.each do |timer|
      values += timer.value.to_d
    end
    values
  end
end
