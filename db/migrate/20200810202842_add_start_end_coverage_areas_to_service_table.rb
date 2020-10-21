class AddStartEndCoverageAreasToServiceTable < ActiveRecord::Migration[5.0]
  def change
  	add_reference :services, :start_area, references: :regions, index: true
  	add_foreign_key :services, :regions, column: :start_area_id

    add_reference :services, :end_area, references: :regions, index: true
  	add_foreign_key :services, :regions, column: :end_area_id
  end
end