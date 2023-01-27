class CreateAuthenticatedAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :authenticated_accounts do |t|
      t.references :user, foreign_key: true, null: true
      t.string :subject_uuid, null: false, index: true
      t.string :email, null: false
      t.string :account_type, null: false

      t.timestamps
    end
  end
end
