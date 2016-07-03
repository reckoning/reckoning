# encoding: utf-8
# frozen_string_literal: true
class TestMail
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :email

  validates :email, email: true

  def initialize(attributes = {})
    return if attributes.nil?
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end
end
