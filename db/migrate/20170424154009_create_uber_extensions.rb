class CreateUberExtensions < ActiveRecord::Migration[5.0]
  def change
    create_table :uber_extensions do |t|
      t.string :product_id
      t.references :itinerary
      t.timestamps
    end
  end
end
