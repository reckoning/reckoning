class ProjectsController < ApplicationController
  before_filter :set_active_nav

  def index
    authorize! :read, Project
    @projects = current_user.projects
      .order(sort_column + " " + sort_direction)
      .page(params.fetch(:page){nil})
      .per(20)
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
      redirect_to projects_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.messages.project"))
    else
      flash.now[:warning] = I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.messages.project"))
      render "new"
    end
  end

  def update
    authorize! :update, project
    if project.update_attributes(project_params)
      redirect_to projects_path, notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.messages.project"))
    else
      flash.now[:warning] = I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.messages.project"))
      render "edit"
    end
  end

  def destroy
    authorize! :destroy, project
    if project.invoices.present?
      redirect_to projects_path, alert: I18n.t(:"messages.destroy.project.failure_dependency")
    else
      if project.destroy
        redirect_to projects_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.messages.project"))
      else
        redirect_to projects_path, alert: I18n.t(:"messages.destroy.failure", resource: I18n.t(:"resources.messages.project"))
      end
    end
  end

  private

  helper_method :project, :customers, :sort_column

  def sort_column
    (Project.column_names + %w[customers.company]).include?(params[:sort]) ? params[:sort] : "id"
  end

  protected

  def set_active_nav
    @active_nav = 'projects'
  end

  def customers
    @customers ||= current_user.customers
  end

  def project_params
    @project_params ||= params.require(:project).permit(
      :customer_id,
      :name,
      :rate,
      :budget,
      tasks_attributes: [
        :id,
        :name,
        :project_id,
        :_destroy
      ]
    )
  end

  def project
    @project ||= Project.where(id: params.fetch(:id){nil}).first
    @project ||= current_user.projects.new project_params
  end
end
