# encoding: utf-8
# frozen_string_literal: true
module ActiveRecord
  class Base
    alias uuid id
  end
end
