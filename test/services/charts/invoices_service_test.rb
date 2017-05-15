# encoding: utf-8
# frozen_string_literal: true

require 'test_helper'

module Charts
  class InvoicesServiceTest < ActiveSupport::TestCase
    let(:account) { accounts :enterprise }

    before do
      @service = InvoicesService.new(account.invoices)
    end

    it "should generate labels" do
      assert @service.labels.length.positive?
    end

    it "should generate datasets" do
      assert @service.datasets.length.positive?
    end
  end
end
