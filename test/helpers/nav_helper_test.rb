# encoding: utf-8
# frozen_string_literal: true

require 'test_helper'

# rubocop:disable Style/ClassAndModuleChildren
class ActionController::TestRequest
  attr_accessor :referer
end

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

  describe "nav_aside?" do
    before do
      @logged_in = true
    end

    test "should return true if nav_layout is aside" do
      assert_equal true, nav_aside?
      @logged_in = false
    end
  end

  describe "nav_layout" do
    test "should fallback to top layout if no user is logged in" do
      assert_equal "top", nav_layout
    end

    describe "with session" do
      before do
        @logged_in = true
      end

      test "should return current_user layout if logged in" do
        assert_equal "aside", nav_layout
        @logged_in = false
      end
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
