class RenameServiceAgencyReference < ActiveRecord::Migration[5.0]
  def change
    rename_column :services, :transportation_agency_id, :agency_id
  end
end
