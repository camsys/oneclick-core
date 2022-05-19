class CreateTravelPatternPurposes < ActiveRecord::Migration[5.0]
  def change
    create_table :travel_pattern_purposes do |t|
      t.references :travel_pattern, foreign_key: true, null: false
      t.references :purpose, foreign_key: true, null: false

      t.timestamps
    end
  end
end
