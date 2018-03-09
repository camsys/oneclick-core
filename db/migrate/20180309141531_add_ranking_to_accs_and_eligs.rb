class AddRankingToAccsAndEligs < ActiveRecord::Migration[5.0]
  def change
    add_column :accommodations, :rank, :integer, null: false, default: 100
    add_column :eligibilities, :rank, :integer, null: false, default: 100
  end
end
