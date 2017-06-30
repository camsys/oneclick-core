class CreateAgencies < ActiveRecord::Migration[5.0]
  def change
    create_table :agencies do |t|
      t.string :type
      t.string :name
      t.string :phone
      t.string :email
      t.string :url
      t.text :description
      t.string :logo
      
      t.timestamps
    end
  end
end
