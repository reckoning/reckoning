class MoveValueToValueDecInTimers < ActiveRecord::Migration
  def up
    Timer.all.each do |timer|
      timer.value_dec = timer.value.to_d
      timer.save
    end
  end

  def down
  end
end
