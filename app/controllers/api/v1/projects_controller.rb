module Api
  module V1
    class ProjectsController < Api::BaseController
      def index
        authorize! :index, Project

        scope = current_account.projects

        state = params.fetch(:state, nil)
        scope = if state.present? && Project.workflow_spec.state_names.include?(state.to_sym)
                  scope.where("projects.workflow_state = ?", state)
                else
                  scope.where("projects.workflow_state = ?", :active)
                end

        scope = scope.where.not(id: without_ids) if without_ids

        sort = params.fetch(:sort, nil)
        scope = if sort.present? && sort == "last_used"
                  scope.includes(:timers).order("timers.created_at desc nulls last")
                else
                  scope.order("name asc")
                end

        render json: scope, each_serializer: ProjectSerializer
      end

      def destroy
        authorize! :destroy, project

        if project.invoices.present?
          Rails.logger.info "Project Destroy Failed: Invoices present"
          render json: ValidationError.new("project.destroy_failure_dependency"), status: :bad_request
        elsif project.destroy
          render json: { message: I18n.t(:"messages.project.destroy.success") }, status: :ok
        else
          Rails.logger.info "Project Destroy Failed: #{project.errors.full_messages.to_yaml}"
          render json: ValidationError.new("project.destroy", project.errors), status: :bad_request
        end
      end

      def archive
        authorize! :archive, project
        project.archive
        project.save
        if project.reload.archived?
          render json: { message: I18n.t(:"messages.project.archive.success") }, status: :ok
        else
          Rails.logger.info "Project Archive Failed: #{project.errors.full_messages.to_yaml}"
          render json: ValidationError.new("project.archive", project.errors), status: :bad_request
        end
      end

      private def without_ids
        @without_ids ||= params[:without_ids]
      end

      private def project_params
        @project_params ||= params.permit(
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
    end
  end
end
