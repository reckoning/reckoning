require "test_helper"

class DropboxControllerTest < ActionController::TestCase
  fixtures :users

  tests ::DropboxController

  let(:user) { users :will }

  describe "unauthorized" do
    it "Unauthorized User can't start dropbox activation"

    it "Unauthorized User can't activate dropbox"

    it "Unauthorized User can't deactivate dropbox"
  end

  describe "happy path" do
    before do
      sign_in user
    end

    it "#start"

    it "#activate"

    it "#deactivate"
  end
end
