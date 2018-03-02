class CreateLyftExtensions < ActiveRecord::Migration[5.0]
  def change
    create_table :lyft_extensions do |t|
      t.string :price_quote_id
      t.references :itinerary
      t.timestamps
    end
  end
end
