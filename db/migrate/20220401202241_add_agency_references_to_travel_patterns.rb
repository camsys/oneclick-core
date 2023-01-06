class AddAgencyReferencesToTravelPatterns < ActiveRecord::Migration[5.0]
  def change
    add_belongs_to :travel_patterns, :agency
  end
end
