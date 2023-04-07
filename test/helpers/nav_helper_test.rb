# frozen_string_literal: true

require "test_helper"

# rubocop:disable Style/ClassAndModuleChildren
class ActionController::TestRequest
  attr_accessor :referer
end
# rubocop:enable Style/ClassAndModuleChildren

class NavHelperTest < ActionView::TestCase
  include NavHelper

  def current_user
    users :will
  end

  def user_signed_in?
    @logged_in
  end

  attr_reader :request

  before do
    @logged_in = false
  end

  describe "active_nav?" do
    test "should return active class for active nav element" do
      @active_nav = "foo"
      assert_equal "active", active_nav?("foo")

      @active_nav = "foo"
      assert_nil active_nav?("bar")

      @active_nav = "foo"
      assert_equal "active", active_nav?(%w[bar foo])
    end
  end

  describe "hide_nav?" do
    test "should return hide class for active nav element" do
      @active_nav = "foo"
      assert_equal "hide", hide_nav?("foo")

      @active_nav = "foo"
      assert_nil hide_nav?("bar")
    end
  end

  describe "back_path" do
    test "should return fallback if current request.referer is blank" do
      assert_equal "foo", back_path("foo")
    end

    test "returns :back if current request.referer is present" do
      @request.referer = true
      assert_equal :back, back_path("foo")
    end
  end

  # def hide_nav?(nav = "home")
  #   return "hide" if nav == @active_nav
  # end

  # def back_path(fallback)
  #   if request.referer.blank?
  #     fallback
  #   else
  #     :back
  #   end
  # end
end
