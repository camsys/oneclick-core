class AddOversightAgencyToService < ActiveRecord::Migration[5.0]
  def change
    create_table :service_oversight_agencies do |t|
      t.references :service, index: true
      t.references :oversight_agency, index: true
    end
    add_foreign_key :service_oversight_agencies,
                    :services,
                    column: :service_id,
                    on_delete: :cascade
    add_foreign_key :service_oversight_agencies,
                    :agencies,
                    column: :oversight_agency_id,
                    on_delete: :cascade
  end
end
