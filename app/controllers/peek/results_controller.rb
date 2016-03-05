module Peek
  class ResultsController < ApplicationController
    skip_authorization_check
    before_action :authenticate_user!, only: []

    def show
      respond_to do |format|
        format.json do
          if request.xhr?
            render json: Peek.adapter.get(params[:request_id])
          else
            render nothing: true, status: :not_found
          end
        end
      end
    end
  end
end
