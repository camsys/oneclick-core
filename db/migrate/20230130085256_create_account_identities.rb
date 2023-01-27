class CreateAccountIdentities < ActiveRecord::Migration[5.0]
  def change
    create_table :account_identities do |t|
      t.references :authenticated_account, foreign_key: true, null: false
      t.string :identity, null: false
      t.string :provider, null: false

      t.timestamps
    end

    add_index :account_identities, [:identity, :provider]
  end
end
