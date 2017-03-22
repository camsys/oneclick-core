class CreateSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :schedules do |t|
      t.references :service, foreign_key: true
      t.integer :day
      t.integer :start_time   # time in seconds from start of day
      t.integer :end_time     # time in seconds from start of day

      t.timestamps
    end
  end
end
