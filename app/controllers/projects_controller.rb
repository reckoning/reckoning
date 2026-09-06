# frozen_string_literal: true

# Only the detail page is left here: it renders the offers and invoices
# panels, which belong to phases B6 and B7. The list and the form are the
# SPA's since B3, and everything they needed — sorting, the customer
# collection, strong params — went with them.
class ProjectsController < ApplicationController
  before_action :set_active_nav

  def show
    authorize! :read, project
    @project_budget_chart_data = Charts::ProjectBudgetService.new(project, project.timers.billable).data
  end

  private def set_active_nav
    @active_nav = "projects"
  end

  private def project
    @project ||= Project.where(id: params.fetch(:id, nil)).first
  end
  helper_method :project
end
