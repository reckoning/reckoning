module ProjectHelper
  def budget_progress(project)
    case project.budget_percent.to_i
    when 90..100
      return "progress-bar-danger"
    when 70..89
      return "progress-bar-warning"
    else
      return "progress-bar-success"
    end
  end
end
