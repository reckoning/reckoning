# encoding: utf-8
# frozen_string_literal: true

json.partial! partial: 'api/v1/users/show', collection: @users, as: :user
