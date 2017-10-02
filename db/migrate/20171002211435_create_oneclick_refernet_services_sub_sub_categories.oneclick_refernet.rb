# This migration comes from oneclick_refernet (originally 20170816165929)
class CreateOneclickRefernetServicesSubSubCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :oneclick_refernet_services_sub_sub_categories do |t|
      t.references :service, 
                   index: { name: :idx_svcs_cat_join_table_on_service_id }, 
                   references: :oneclick_refernet_services
      t.references :sub_sub_category, 
                   index: { name: :idx_svcs_cat_join_table_on_sub_sub_category_id },
                   references: :oneclick_refernet_services

      t.timestamps
    end
    
    add_foreign_key :oneclick_refernet_services_sub_sub_categories, 
                    :oneclick_refernet_services,
                    column: :service_id
    add_foreign_key :oneclick_refernet_services_sub_sub_categories, 
                    :oneclick_refernet_sub_sub_categories,
                    column: :sub_sub_category_id
  end
end
