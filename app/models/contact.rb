# encoding: utf-8
# frozen_string_literal: true

class Contact < ActiveRecord::Base
  validates :email, presence: true, uniqueness: true
end
