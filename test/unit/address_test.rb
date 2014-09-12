require 'test_helper'

class AddressTest < ActiveSupport::TestCase

  it "should set contact with all given fields" do
    address = Address.new(email: "12345@01234.de", telefon: "12345", fax: "01234")
    address.set_contact
    assert_equal address.contact, "#{address.email} | #{address.telefon} | #{address.fax}"
  end

  it "should respond to resource" do
    address = Address.new
    assert_respond_to address, :resource
  end

end
