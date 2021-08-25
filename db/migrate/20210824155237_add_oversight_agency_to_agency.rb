class AddOversightAgencyToAgency < ActiveRecord::Migration[5.0]
  def change
    create_table :agency_oversight_agencies do |t|
      t.references :transportation_agency, index: true
      t.references :oversight_agency, index: true
    end
      add_foreign_key :agency_oversight_agencies,
                      :agencies,
                      column: :transportation_agency_id,
                      on_delete: :cascade
      add_foreign_key :agency_oversight_agencies,
                      :agencies,
                      column: :oversight_agency_id,
                      on_delete: :cascade
  end
end
