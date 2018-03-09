class AddRankingToAccsAndEligs < ActiveRecord::Migration[5.0]
  def change
    add_column :accommodations, :index, :integer, null: false, default: 100
    add_column :eligibilities, :index, :integer, null: false, default: 100
  end
end
