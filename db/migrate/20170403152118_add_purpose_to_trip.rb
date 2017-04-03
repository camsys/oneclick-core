class AddPurposeToTrip < ActiveRecord::Migration[5.0]
  def change
  	add_reference :trips, :purpose, index: true, foreign_key: true
  end
end
