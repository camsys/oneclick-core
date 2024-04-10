class AddSpatialIndexToRegions < ActiveRecord::Migration[5.0]
  def change
    unless index_exists?(:regions, :geom, using: :gist)
      add_index(:regions, :geom, using: :gist)
    end
  end
end
