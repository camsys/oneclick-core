class AddServiceToLandmarks < ActiveRecord::Migration[5.0]
  def change
    add_reference :landmarks, :service, index: true, foreign_key: true
  end
end
