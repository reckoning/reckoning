# frozen_string_literal: true

class CreateParents < ActiveRecord::Migration
  def change
    create_table :parents, &:timestamps
  end
end
