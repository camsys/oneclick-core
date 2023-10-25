class AddSearchTextToLandmarks < ActiveRecord::Migration[5.0]
  def change
    add_column :landmarks, :search_text, :text
    add_index :landmarks, :search_text
  end
end
