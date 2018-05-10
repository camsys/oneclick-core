class CreateJoinTableTripsAccommodations < ActiveRecord::Migration[5.0]
  def change
    create_join_table :trips, :accommodations do |t|
       t.index [:trip_id, :accommodation_id]
       #t.index [:accommodation_id, :trip_id]
    end

    create_join_table :trips, :eligibilities do |t|
      t.index [:trip_id, :eligibility_id]
      #t.index [:accommodation_id, :trip_id]
    end
  end
end
