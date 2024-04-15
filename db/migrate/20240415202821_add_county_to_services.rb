class AddCountyToServices < ActiveRecord::Migration[5.0]
  def change
    add_reference :services, :county, foreign_key: true
  end
end
