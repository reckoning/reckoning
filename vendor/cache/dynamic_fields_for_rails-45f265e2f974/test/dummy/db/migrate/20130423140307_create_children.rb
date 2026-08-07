# frozen_string_literal: true

class CreateChildren < ActiveRecord::Migration
  def change
    create_table :children do |t|
      t.integer :parent_id
      t.timestamps
    end
  end
end
