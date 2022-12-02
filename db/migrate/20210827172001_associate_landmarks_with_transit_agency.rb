class AssociateLandmarksWithTransitAgency < ActiveRecord::Migration[5.0]
  def change
    add_reference :landmarks, :agency, index: true
    add_foreign_key :landmarks, :agencies
  end
end
