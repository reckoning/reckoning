class ErrorsController < ApplicationController
  skip_authorization_check
  before_action :authenticate_user!, only: []

  def not_found
    render status: 404
  end

  def server_error
    render file: "public/500.html", status: 500, layout: false
  end
end
