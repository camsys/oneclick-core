SimpleTranslationEngine.configure do |config|
  
  # # Only show Translation Keys namespaced under "global" or "pages"
  # config.visible_key_scope = lambda {
  #   where("name LIKE ? OR name LIKE ?", "global.%", "pages.%")
  # }
  
  # Hide any translation keys with "REFERNET" in the name
  config.hidden_key_scope = lambda {
    where("name LIKE ?", "%REFERNET%")
  }
  
end

# Extend Translation Engine classes with additional functionality
Rails.configuration.to_prepare do

  # Inject auth functionality into TranslationsController
  TranslationsController.class_eval do
    include TranslationsControllerExtensions
    authorize_resource
  end

  TranslationKeysController.class_eval do
    include TranslationsControllerExtensions
    authorize_resource
  end



  # If AWS_LOCALE_STORAGE is set, trigger upload of locale to AWS every time a record is updated
  if ENV['AWS_LOCALE_STORAGE'] == "true" && 
     ENV["RAILS_ENV"] == "production" # Only upload locales in production environment
    Translation.class_eval do
      include AwsLocaleUploadable
    end  
    TranslationKey.class_eval do
      include AwsLocaleUploadable
    end
  end

end
