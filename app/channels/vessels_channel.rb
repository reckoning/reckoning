# encoding: utf-8
# frozen_string_literal: true

class VesselsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "vessels_#{current_user.id}"
  end
end
