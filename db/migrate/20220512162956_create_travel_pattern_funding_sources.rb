class CreateTravelPatternFundingSources < ActiveRecord::Migration[5.0]
  def change
    create_table :travel_pattern_funding_sources do |t|
      t.references :travel_pattern, foreign_key: true, null: false
      t.references :funding_source, foreign_key: true, null: false

      t.timestamps
    end
  end
end
