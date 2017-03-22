class AddDayIndexToSchedules < ActiveRecord::Migration[5.0]
  def change
    add_index :schedules, :day
  end
end
