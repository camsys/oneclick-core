class AddExternalPurposeToTrip < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :external_purpose, :string
  end
end
