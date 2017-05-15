# encoding: utf-8
# frozen_string_literal: true

json.partial! partial: 'api/v1/projects/show', collection: @projects, as: :project
