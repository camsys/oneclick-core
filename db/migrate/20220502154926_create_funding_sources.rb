class CreateFundingSources < ActiveRecord::Migration[5.0]
  def change
    create_table :funding_sources do |t|
      t.string :name, null: false
      t.string :description, null: false
      t.references :agency, foreign_key: true, null: false

      t.timestamps
    end
  end
end
