# frozen_string_literal: true

module Api
  class BaseController < ActionController::API
    include ::AccountsConcern

    before_action :authenticate_user!

    respond_to :json

    check_authorization

    rescue_from CanCan::AccessDenied do |exception|
      render json: {message: exception.message}, status: :forbidden
    end

    # Permit params from an OpenAPI input component. The schema spells
    # properties camelCase (matching the wire format jbuilder emits), while
    # ActiveRecord wants snake_case — so both the incoming keys and the permit
    # list derived from the component are underscored before they meet.
    private def openapi_params(component)
      params
        .deep_transform_keys { |key| key.to_s.underscore }
        .permit(*underscore_permit_list(component.permitted_params))
    end

    private def underscore_permit_list(list)
      list.map do |entry|
        next entry.to_s.underscore.to_sym unless entry.is_a?(Hash)

        entry.to_h do |key, value|
          nested = value.is_a?(Array) ? underscore_permit_list(value) : value
          [key.to_s.underscore.to_sym, nested]
        end
      end
    end

    private def not_found(message = I18n.t("messages.record_not_found.base"))
      render json: {code: "not_found", message: message}, status: :not_found
    end

    def resource_message(resource, action, state)
      I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t(:"resources.#{resource}"))
    end
  end
end
