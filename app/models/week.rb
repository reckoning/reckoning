class Week < ActiveRecord::Base
  belongs_to :user
  has_many :timers
  has_and_belongs_to_many :tasks

  accepts_nested_attributes_for :timers, allow_destroy: true
end
