class CreateEligibilities < ActiveRecord::Migration[5.0]
  def change
    create_table :eligibilities do |t|
      t.string :code,  null: false, unique: true
      t.timestamps
    end
  end
end
