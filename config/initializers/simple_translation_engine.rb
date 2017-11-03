SimpleTranslationEngine.configure do |config|
  
  # Only show Translation Keys namespaced under "global" or "pages"
  config.visible_key_scope = lambda {
    where("name LIKE ? OR name LIKE ?", "global.%", "pages.%")
  }
  
  # Hide any translation keys with "REFERNET" in the name
  config.hidden_key_scope = lambda {
    where("name ILIKE ?", "%REFERNET%")
  }
  
end

# Extend Translation Engine classes with additional functionality
Rails.configuration.to_prepare do

  # Inject auth functionality into TranslationsController
  TranslationsController.class_eval do
    include TranslationsControllerExtensions
    authorize_resource
  end

  Translation.class_eval do
    include TranslationModelExtensions
  end
  
  TranslationKey.class_eval do
    include TranslationModelExtensions
  end

end
