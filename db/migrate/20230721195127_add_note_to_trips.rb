class AddNoteToTrips < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :note, :text
  end
end
