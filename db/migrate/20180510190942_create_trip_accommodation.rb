class CreateTripAccommodation < ActiveRecord::Migration[5.0]
  def change
    create_table :trip_accommodations do |t|
      t.belongs_to :trip, null: false, index: true
      t.belongs_to :accommodation, null: false, index: true
    end

    create_table :trip_eligibilities do |t|
      t.belongs_to :trip, null: false, index: true
      t.belongs_to :eligibility, null: false, index: true
    end

    create_table :trip_purposes do |t|
      t.belongs_to :trip, null: false, index: true
      t.belongs_to :purpose, null: false, index: true
    end
  end
end
