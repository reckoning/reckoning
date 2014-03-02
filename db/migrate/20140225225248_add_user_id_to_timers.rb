class AddUserIdToTimers < ActiveRecord::Migration
  def up
    add_column :tasks, :user_id, :integer

    User.all.each do |user|
      user.projects.each do |project|
        project.tasks.each do |task|
          task.user_id = user.id
          task.save
        end
      end
    end
  end

  def down
    remove_column :tasks, :user_id
  end
end
