# frozen_string_literal: true

class AfaType < ApplicationRecord
  extend Mobility
  translates :name, type: :string
end
