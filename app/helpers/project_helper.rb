module ProjectHelper
  def budget_progress(project)
    case
    when project.budget_percent.to_f > 90.0
      "progress-bar-danger"
    when project.budget_percent.to_f > 70.0
      "progress-bar-warning"
    else
      "progress-bar-success"
    end
  end
end
