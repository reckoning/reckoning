require 'test_helper'

class ProjectTest < ActiveSupport::TestCase

  def setup
    @customer = Customer.create({address_attributes: {company: "test"}})
  end

  def teardown
    Customer.destroy_all
    Project.destroy_all
  end

  test "should not save project without customer_id" do
    project = Project.new({name: "Project", rate: 99.0})
    assert !project.save
  end

  test "should not save project without name" do
    project = Project.new({customer_id: @customer.id, rate: 99.0})
    assert !project.save
  end

  test "if rate is empty it should fall back to 0.0" do
    project = Project.new({customer_id: @customer.id, name: "Project"})
    project.save
    assert project.rate == 0.0
  end

  test "should save project with customer_id & name & rate" do
    #p @customer.to_yaml
    project = Project.new({customer_id: @customer.id, name: "Project", rate: 99.0})
    assert project.save
  end

  test "should respond to invoices" do
    project = Project.new({customer_id: @customer.id, name: "Project", rate: 99.0})
    project.save
    assert_respond_to project, :invoices
  end

end
