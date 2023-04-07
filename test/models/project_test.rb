# frozen_string_literal: true

require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  fixtures :customers

  let(:customer) { customers :starfleet }

  it "should not save project without customer_id" do
    project = Project.new(name: "Project", rate: 99.0)
    assert_not project.valid?
  end

  it "should not save project without name" do
    project = Project.new(customer_id: customer.id, rate: 99.0)
    assert_not project.valid?
  end

  it "if rate is empty it should fall back to 0.0" do
    project = Project.new(customer_id: customer.id, name: "Project")
    assert project.rate.zero?
  end

  it "should save project with customer_id & name & rate" do
    project = Project.new(customer_id: customer.id, name: "Project", rate: 99.0)
    assert project.valid?
  end

  it "should respond to invoices" do
    project = Project.new(customer_id: customer.id, name: "Project", rate: 99.0)
    assert_respond_to project, :invoices
  end
end
