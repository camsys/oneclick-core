class AddCommenterIdToComments < ActiveRecord::Migration[5.0]
  def change
    add_reference :comments, :commenter, references: :users, index: true
    add_foreign_key :comments, :users, column: :commenter_id
  end
end
