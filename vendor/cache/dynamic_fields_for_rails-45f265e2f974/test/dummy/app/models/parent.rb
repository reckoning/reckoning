# frozen_string_literal: true

class Parent < ApplicationRecord
  has_many :children
  accepts_nested_attributes_for :children, allow_destroy: true
end
