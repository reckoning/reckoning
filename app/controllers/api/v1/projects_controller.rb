# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.project", id: params[:id]))
      end

      def index
        authorize! :index, Project

        scope = current_account.projects.includes(:customer)

        state = params.fetch(:state, nil)
        scope = if state.present? && Project.workflow_spec.state_names.include?(state.to_sym)
          scope.where(workflow_state: state)
        else
          scope.where(workflow_state: :active)
        end

        scope = scope.where.not(id: without_ids) if without_ids

        sort = params.fetch(:sort, nil)
        @projects = if sort.present? && sort == "used"
          scope.includes(:timers).order("timers.created_at desc nulls last")
        else
          scope.order(name: :asc)
        end
      end

      def show
        @project = current_account.projects.find(params[:id])
        authorize! :read, @project
      end

      def create
        @project = current_account.projects.new(project_params)
        authorize! :create, @project

        if @project.save
          render :show, status: :created
        else
          render json: ValidationError.new("project.create", @project.errors), status: :bad_request
        end
      end

      def update
        @project = current_account.projects.find(params[:id])
        authorize! :update, @project

        return render :show if @project.update(project_params)

        render json: ValidationError.new("project.update", @project.errors), status: :bad_request
      end

      def unarchive
        @project = current_account.projects.find(params[:id])
        authorize! :archive, @project

        if @project.archived? && @project.unarchive!
          render json: {message: resource_message(:project, :unarchive, :success)}, status: :ok
        else
          render json: ValidationError.new("project.unarchive"), status: :bad_request
        end
      end

      def destroy
        @project = current_account.projects.find(params[:id])
        authorize! :destroy, @project

        if @project.invoices.present?
          Rails.logger.info "Project Destroy Failed: Invoices present"
          render json: ValidationError.new("project.destroy_failure_dependency"), status: :bad_request
        elsif @project.destroy
          render json: {message: resource_message(:project, :destroy, :success)}, status: :ok
        else
          Rails.logger.info "Project Destroy Failed: #{@project.errors.full_messages.to_yaml}"
          render json: ValidationError.new("project.destroy", @project.errors), status: :bad_request
        end
      end

      def archive
        @project = current_account.projects.find(params[:id])
        authorize! :archive, @project
        if @project.archived?
          Rails.logger.info "Project Archive Failed"
          render json: ValidationError.new("project.archive"), status: :bad_request
        else
          @project.archive!
          @project.save
          render json: {message: resource_message(:project, :archive, :success)}, status: :ok
        end
      end

      private def without_ids
        @without_ids ||= params[:withoutIds]
      end

      private def project_params
        @project_params ||= openapi_params(::V1::Schemas::Inputs::ProjectInput)
      end
    end
  end
end
