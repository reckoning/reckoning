require 'test_helper'

class AddressTest < ActiveSupport::TestCase

  test "should split name into firstnam and lastname" do
    firstname = "William"
    lastname = "Riker"
    address = create(:address, name: "#{firstname} #{lastname}")
    assert_equal address.firstname, firstname
    assert_equal address.lastname, lastname
  end

  test "should set contact with all given fields" do
    email = "12345@01234.de"
    telefon = "12345"
    fax = "01234"
    address = create(:address, email: email, telefon: telefon, fax: fax)
    assert_equal address.contact, "#{email} | #{telefon} | #{fax}"
  end

  test "should respond to resource" do
    address = build(:address)
    assert_respond_to address, :resource
  end

end
