# frozen_string_literal: true

module ProjectHelper
  def budget_progress(project)
    if project.budget_percent.to_f > 90.0
      'progress-bar-danger'
    elsif project.budget_percent.to_f > 70.0
      'progress-bar-warning'
    else
      'progress-bar-success'
    end
  end
end
