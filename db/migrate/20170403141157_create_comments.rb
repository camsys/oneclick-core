class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.text :comment
      t.string :locale
      t.references :commentable, polymorphic: true, index: true

      t.timestamps
    end
  end
end
