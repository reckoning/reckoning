# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      format.html do
        render status: :not_found, layout: 'error'
      end
      format.json do
        render json: { code: 'not_found', message: 'Not Found' }, status: :not_found
      end
    end
  end

  def server_error
    respond_to do |format|
      format.html do
        render status: :internal_server_error, layout: 'error'
      end
      format.json do
        render json: { code: 'server_error', message: 'Server Error' }, status: :internal_server_error
      end
    end
  end
end
