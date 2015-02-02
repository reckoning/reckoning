class ErrorsController < ActionController::Base
  def not_found
    format.html {
      render status: :not_found, layout: "error"
    }
    format.json {
      render json: {code: "not_found", message: "Not Found"}, status: :not_found
    }
  end

  def server_error
    respond_to do |format|
      format.html {
        @without_links = true
        render status: 500, layout: "error"
      }
      format.json {
        render json: {code: "server_error", message: "Server Error"}, status: 500
      }
    end
  end
end
