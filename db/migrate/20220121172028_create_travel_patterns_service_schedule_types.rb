class CreateTravelPatternsServiceScheduleTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :travel_patterns_service_schedule_types do |t|
      t.string :name
      t.string :description
      t.timestamps
    end
  end
end
