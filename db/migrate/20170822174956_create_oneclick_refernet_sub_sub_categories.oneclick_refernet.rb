# This migration comes from oneclick_refernet (originally 20170816135227)
class CreateOneclickRefernetSubSubCategories < ActiveRecord::Migration[5.0]
  
  def change
    create_table :oneclick_refernet_sub_sub_categories do |t|
      t.string :name, index: true
      t.references :sub_category, references: :oneclick_refernet_sub_categories

      t.timestamps
    end
    
    add_foreign_key :oneclick_refernet_sub_sub_categories, 
                    :oneclick_refernet_sub_categories, 
                    column: :sub_category_id
  end
  
end
