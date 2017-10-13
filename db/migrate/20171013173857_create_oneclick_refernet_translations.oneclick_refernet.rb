# This migration comes from oneclick_refernet (originally 20171010210136)
class CreateOneclickRefernetTranslations < ActiveRecord::Migration[5.0]
  def change
    create_table :oneclick_refernet_translations do |t|
    	t.string :key, index: true
    	t.string :locale
    	t.text 	 :value

      t.timestamps
    end
  end
end
