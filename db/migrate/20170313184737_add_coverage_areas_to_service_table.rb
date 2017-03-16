class AddCoverageAreasToServiceTable < ActiveRecord::Migration[5.0]
  def change
  	add_reference :services, :start_or_end_area, references: :regions, index: true
  	add_foreign_key :services, :regions, column: :start_or_end_area_id

    add_reference :services, :trip_within_area, references: :regions, index: true
  	add_foreign_key :services, :regions, column: :trip_within_area_id
  end
end
