# frozen_string_literal: true

json.partial! partial: "api/v1/backend/users/show", collection: @users, as: :user
