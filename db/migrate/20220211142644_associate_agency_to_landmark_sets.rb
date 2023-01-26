class AssociateAgencyToLandmarkSets < ActiveRecord::Migration[5.0]
  def change
    add_reference :landmark_sets,:agency, index: true
    add_foreign_key :landmark_sets, :agencies
  end
end
