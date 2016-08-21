# encoding: utf-8
# frozen_string_literal: true
class ToursChannel < ApplicationCable::Channel
  def subscribed
    stream_from "tours_#{current_user.id}"
  end
end
