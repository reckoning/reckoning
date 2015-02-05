class ProjectsController < ApplicationController
  before_action :set_active_nav
  before_action :check_dependencies, only: [:new]

  def index
    authorize! :read, Project
    @customers = current_account.customers.order(sort_column + " " + sort_direction)
                 .page(params.fetch(:page, nil))
                 .per(20)
  end

  def show
    authorize! :read, project
  end

  def new
    authorize! :create, Project
    @project = Project.new
  end

  def edit
    authorize! :update, project
  end

  def create
    authorize! :create, Project
    if project.save
      redirect_to projects_path, notice: I18n.t(:"messages.project.create.success")
    else
      flash.now[:warning] = I18n.t(:"messages.project.create.failure")
      render "new"
    end
  end

  def update
    authorize! :update, project
    if project.update_attributes(project_params)
      redirect_to projects_path, notice: I18n.t(:"messages.project.update.success")
    else
      flash.now[:warning] = I18n.t(:"messages.project.update.failure")
      render "edit"
    end
  end

  def destroy
    authorize! :destroy, project
    if project.invoices.present?
      redirect_to projects_path, alert: I18n.t(:"messages.project.destroy.failure_dependency")
    else
      if project.destroy
        redirect_to projects_path, notice: I18n.t(:"messages.project.destroy.success")
      else
        redirect_to projects_path, alert: I18n.t(:"messages.project.destroy.failure")
      end
    end
  end

  private def sort_column
    (Project.column_names + %w(customers.company)).include?(params[:sort]) ? params[:sort] : "name"
  end
  helper_method :sort_column

  private def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : "asc"
  end

  private def set_active_nav
    @active_nav = 'projects'
  end

  private def customers
    @customers ||= current_account.customers
  end
  helper_method :customers

  private def project_params
    @project_params ||= params.require(:project).permit(
      :customer_id,
      :name,
      :rate,
      :budget,
      :budget_on_dashboard,
      tasks_attributes: [
        :id,
        :name,
        :project_id,
        :_destroy
      ]
    )
  end

  private def project
    @project ||= Project.where(id: params.fetch(:id, nil)).first
    @project ||= current_account.projects.new project_params
  end
  helper_method :project

  private def check_dependencies
    return if current_account.customers.present?
    redirect_to new_customer_path, alert: I18n.t(:"messages.project.missing_customer")
  end
end
