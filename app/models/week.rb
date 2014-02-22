class Week < ActiveRecord::Base
  belongs_to :user
  has_many :timers
  has_and_belongs_to_many :tasks
  has_many :projects, through: :tasks

  accepts_nested_attributes_for :timers, allow_destroy: true


  before_save :reject_empty_timers


  def reject_empty_timers
    timers.reject do |timer|
      if timer.value.blank?
        timers.delete(timer)
      end
    end
  end
end
