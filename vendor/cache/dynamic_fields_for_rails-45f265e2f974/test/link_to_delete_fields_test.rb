# frozen_string_literal: true

require 'test_helper'

class LinkToDeleteFieldsTest < ActionView::TestCase
  tests ActionView::Helpers::FormHelper

  include DynamicFieldsForHelper

  def form_for(*)
    @output_buffer = super
  end

  def setup
    @parent = Parent.create
    @parent.children.create
  end

  test 'generates a delete fields link' do
    form_for(@parent, url: '/') do |form|
      form.fields_for :children, @parent.children do |fields|
        link_to_delete_fields(fields, name: 'Test')
      end
    end

    assert_match(%r{<input(.*)value=\"false\"(.*)name=\"parent\[children_attributes\](.*)\[_destroy\]\"(.*)\/>}, @output_buffer)
    assert_match(%r{<a(.*)class=\"remove_fields(.*)\"(.*)>Test<\/a>}, @output_buffer)
  end

  test 'generates a deletes fields link with block if it is given' do
    form_for(@parent, url: '/') do |form|
      form.fields_for :children, @parent.children do |fields|
        link_to_delete_fields fields do
          content_tag 'div', 'Test'
        end
      end
    end

    assert_match(%r{<input(.*)value=\"false\"(.*)name=\"parent\[children_attributes\](.*)\[_destroy\]\"(.*)\/>}, @output_buffer)
    assert_match(%r{<a(.*)class=\"remove_fields(.*)\"(.*)><div>Test<\/div><\/a>}, @output_buffer)
  end
end
