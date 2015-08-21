class SetDefaultPlanToAllAccounts < ActiveRecord::Migration
  def up
    Account.find_each do |account|
      account.plan = :free
      account.save
    end
  end

  def down
  end
end
