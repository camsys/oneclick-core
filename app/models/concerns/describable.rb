# Sets up translatable descriptions for the including model
module Describable
  
  def self.included(base)

    # This block of code creates localized description setters and getters
    I18n.available_locales.each do |locale|
      
      # Create localized getter
      define_method("#{locale}_description") do
        self.send(:description, locale)
      end
      
      # Create localized setter
      define_method("#{locale}_description=") do |value|
        self.send(:set_description_translation, locale, value)
      end
    end
    
    # Destroy any description translations along with the including model
    base.before_destroy :delete_translations
  
  end
  
  # Get's the description, translated into the passed locale
  def description(locale=I18n.default_locale)
    SimpleTranslationEngine.translate(locale, description_translation_key)
  end
  
  # Sets the description for the given locale
  def set_description_translation(locale, value)
    SimpleTranslationEngine.set_translation(locale, description_translation_key, value)
  end
  
  # Deletes the translations associated with this model
  def delete_translations
    TranslationKey.find_by(name: description_translation_key).try(:destroy)
  end
  
  # Builds a description translation key based on the class name and id of the including model
  def description_translation_key
    "#{self.class.name.downcase}_#{self.id}_description"
  end
  
  # Returns a hash of all description translations, keyed by locale
  def descriptions
    I18n.available_locales.map {|l| [l, description(l)] }.to_h
  end
  
  # Sets the descriptions from a hash of locale:value pairs
  def set_descriptions_from_hash(desc_hash={})
    desc_hash.each do |loc, desc|
      set_description_translation(loc, desc)
    end
  end
  
end
