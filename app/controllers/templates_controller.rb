# encoding: utf-8
# frozen_string_literal: true
class TemplatesController < ApplicationController
  skip_authorization_check
  layout false

  def show
    route = request.path.sub("/template/", "")
    route_parts = route.split("_")
    render "templates/#{route_parts.reverse.join('/')}"
  end
end
