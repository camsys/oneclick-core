class CreateUserEligibilities < ActiveRecord::Migration[5.0]
  def change
    create_table :user_eligibilities do |t|
      t.references :user, foreign_key: true, index: true
      t.references :eligibility, foreign_key: true, index: true
      t.boolean :value

      t.timestamps
    end

  end
end
