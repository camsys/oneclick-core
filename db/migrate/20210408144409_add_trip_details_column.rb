class AddTripDetailsColumn < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :details, :text
  end
end
