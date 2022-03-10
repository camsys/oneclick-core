class AssociateCustomGeographyToTransitAgency < ActiveRecord::Migration[5.0]
  def change
    add_reference :custom_geographies, :agency, index: true
    add_foreign_key :custom_geographies, :agencies
  end
end
