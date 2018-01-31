# frozen_string_literal: true

class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notifications_#{current_user.id}_#{params[:room]}"
  end
end
