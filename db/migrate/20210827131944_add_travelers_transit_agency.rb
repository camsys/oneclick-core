class AddTravelersTransitAgency < ActiveRecord::Migration[5.0]
  # NOTE: traveler_transportation_agency ends up being too long for index name
  # ... so using traveler_transit_agency
  def change
    create_table :traveler_transit_agencies do |t|
      t.references :user, index: true
      t.references :transportation_agency, index: true
    end
    add_foreign_key :traveler_transit_agencies,
                    :users,
                    column: :user_id,
                    on_delete: :cascade
    add_foreign_key :traveler_transit_agencies,
                    :agencies,
                    column: :transportation_agency_id,
                    on_delete: :cascade
  end
end
