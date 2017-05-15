# encoding: utf-8
# frozen_string_literal: true

class TimersChannel < ApplicationCable::Channel
  def subscribed
    stream_from "timers_#{current_user.id}_#{params[:room]}"
  end
end
