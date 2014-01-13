require 'test_helper'

class AwesomeOpenStructTest < ActiveSupport::TestCase

  test "should merge values correctly" do
    base_hash = {foo: {"bar" => false, "baz" => 1234}}
    struct = AwesomeOpenStruct.new(base_hash)
    hash = {foo: {"bar" => true}}
    result_hash = {foo: {"bar" => true, "baz" => 1234}}
    struct.merge hash
    assert_equal result_hash, struct.to_hash
  end

end
