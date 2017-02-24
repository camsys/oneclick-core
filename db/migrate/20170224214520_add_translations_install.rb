class AddTranslationsInstall < ActiveRecord::Migration[5.0]
  def change
  	Rake::Task['simple_translation_engine:install'].invoke
  	Rake::Task['simple_translation_engine:update'].invoke
  end
end
