class RemoveDescriptionFromAgencies < ActiveRecord::Migration[5.0]
  def change
    remove_column :agencies, :description, :text
  end
end
