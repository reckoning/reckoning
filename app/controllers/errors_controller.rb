class ErrorsController < ActionController::Base
  def not_found
    render status: 404, layout: "error"
  end

  def server_error
    @without_links = true
    render status: 500, layout: "error"
  end
end
