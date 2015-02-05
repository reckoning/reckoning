class TransferNameFromContactInformation < ActiveRecord::Migration
  def up
    User.all.each do |user|
      user.name = user.contact_information["name"]
      user.save!
    end
  end

  def down
  end
end
