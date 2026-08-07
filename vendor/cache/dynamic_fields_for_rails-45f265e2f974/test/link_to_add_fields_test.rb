# frozen_string_literal: true

require 'test_helper'

class LinkToAddFieldsTest < ActionView::TestCase
  tests ActionView::Helpers::FormHelper

  include DynamicFieldsForHelper

  def form_for(*)
    @output_buffer = super
  end

  def setup
    @parent = Parent.create
    @parent.children.build
  end

  test 'generates a add fields link' do
    form_for(@parent, url: '/') do |form|
      link_to_add_fields(form, 'children', name: 'Test')
    end

    assert_match(%r{<a(.*)class=\"add_fields(.*)\"(.*)>Test<\/a>}, @output_buffer)
  end

  test 'generates a add fields link with block if it is given' do
    form_for(@parent, url: '/') do |form|
      link_to_add_fields form, 'children' do
        content_tag 'div', 'Test'
      end
    end

    assert_match(%r{<a(.*)class=\"add_fields(.*)\"(.*)><div>Test<\/div><\/a>}, @output_buffer)
  end
end
