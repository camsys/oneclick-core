class CreateTravelPatterns < ActiveRecord::Migration[5.0]
  def change
    create_table :travel_patterns do |t|
      t.string :name, null: false
      t.text :description
    end
  end
end
