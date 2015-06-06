class AddUsersToTimers < ActiveRecord::Migration
  def up
    Timer.all.each do |timer|
      timer.user_id = timer.task.project.customer.account.users.first.id
      timer.save
    end
  end

  def down
  end
end
