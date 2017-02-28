class AddPreferredLocaleToUser < ActiveRecord::Migration[5.0]
  def change
  	add_reference :users, :preferred_locale, references: :locales, index: true
  	add_foreign_key :users, :locales, column: :preferred_locale_id
  end
end