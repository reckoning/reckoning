require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  def setup
    @setting = create(:setting, keypath: "foo.bar", value: 1)
  end

  def tear_down
    Setting.destroy_all
  end

  test "should create correct hash" do
    hash = {foo: {"bar" => 1}}
    assert_equal hash, Setting.to_h
  end
end
