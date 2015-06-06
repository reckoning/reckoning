class User < ActiveRecord::Base
  has_many :invoices, dependent: :destroy
  has_many :weeks, dependent: :destroy
  has_many :customers, dependent: :destroy
end

class MoveInvoicesProjectsCustomersAndWeeksToAccount < ActiveRecord::Migration
  def up
    Account.all.each do |account|
      user = account.users.first
      account.customers = user.customers
      account.invoices = user.invoices
      account.weeks = user.weeks
      account.save!
    end
  end

  def down
  end
end
