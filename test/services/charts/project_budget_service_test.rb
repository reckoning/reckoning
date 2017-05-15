# encoding: utf-8
# frozen_string_literal: true

require 'test_helper'

module Charts
  class ProjectBudgetServiceTest < ActiveSupport::TestCase
    fixtures :projects, :timers

    let(:project) { projects :narendra3 }

    before do
      @service = ProjectBudgetService.new(project, project.timers.billable)
    end

    it "should generate labels" do
      assert @service.ticks.length.positive?
      assert @service.labels.length.positive?
    end

    it "should generate datasets" do
      assert @service.datasets.length.positive?
    end

    it "should add budget and ticks to data hash" do
      assert @service.data[:ticks].present?
      assert @service.data[:budget].present?
    end
  end
end
