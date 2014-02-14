class Task < ActiveRecord::Base
  validates_presence_of :project_id, :name

  belongs_to :project
  has_many :timers
  has_and_belongs_to_many :weeks

end
