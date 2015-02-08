module Api
  module V1
    class ProjectsController < Api::BaseController
      respond_to :json

      def destroy
        authorize! :destroy, project

        if project.invoices.present?
          render json: ValidationError.new("project.destroy_failure_dependency"), status: :bad_request
        else
          if project.destroy
            render json: { message: I18n.t(:"messages.project.destroy.success") }, status: :ok
          else
            render json: ValidationError.new("project.destroy", project.errors), status: :bad_request
          end
        end
      end

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
    end
  end
end
