class Task < ActiveRecord::Base
  belongs_to :project
  has_many :timers, dependent: :destroy
  # TODO: Refactor with frontend
  # rubocop:disable Rails/HasAndBelongsToMany
  has_and_belongs_to_many :weeks

  validates :project_id, :name, presence: true

  def project_name
    project.name_with_customer
  end

  def timer_values
    values = 0.0
    timers.each do |timer|
      values += timer.value.to_d
    end
    values
  end
end
