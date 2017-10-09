# This migration comes from oneclick_refernet (originally 20170816134752)
class CreateOneclickRefernetSubCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :oneclick_refernet_sub_categories do |t|
      t.string :name, index: true
      t.references :category, references: :oneclick_refernet_categories

      t.timestamps
    end
    
    add_foreign_key :oneclick_refernet_sub_categories, 
                    :oneclick_refernet_categories, 
                    column: :category_id
  end
end
