class AssociateAgencyAndAgencyType < ActiveRecord::Migration[5.0]
  def change
    add_reference :agencies, :agency_type, index: true
    add_foreign_key :agencies, :agency_types

  end
end
