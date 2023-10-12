module Api
  module V1
    class DocsController < ActionController::Base
      include Swagger::Blocks

      swagger_root do
        key :swagger, '2.0'
        key :openapi, '3.1.0'
        info do
          key :version, '1.0.0'
          key :title, 'Reckoning Api Schema V1'
          key :description, ''
          key :termsOfService, 'https://reckoning.me/terms'
          contact do
            key :name, 'Marten Klitzke'
            key :url, 'https://reckoning.me'
            key :email, 'info@reckoning.me'
          end
          license do
            key :name, 'GNU General Public License v3.0'
            key :url, 'https://github.com/reckoning/reckoning/blob/main/LICENSE'
          end
        end
        tag do
          key :name, 'customers'
          key :description, 'Customers'
        end
        tag do
          key :name, 'users'
          key :description, 'Users'
        end
        tag do
          key :name, 'holidays'
          key :description, 'Holidays'
        end
        tag do
          key :name, 'projects'
          key :description, 'Projects'
        end
        tag do
          key :name, 'sessions'
          key :description, 'Sessions'
        end
        tag do
          key :name, 'users'
          key :description, 'Users'
        end
        tag do
          key :name, 'timers'
          key :description, 'Timers'
        end
        key :host, 'reckoning.me'
        key :basePath, '/api/v1'
        key :consumes, ['application/json']
        key :produces, ['application/json']
      end

      # A list of all classes that have swagger_* declarations.
      SWAGGERED_CLASSES = [
        Api::V1::TimersController,
        Timer,
        self,
      ].freeze

      def index
        render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
      end
    end
  end
end
