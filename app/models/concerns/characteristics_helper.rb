# Provides helper methods for dealing with accommodations, 
# eligibilities, and purposes.
module CharacteristicsHelper
  
  TRANSLATION_TYPES = [:name, :note, :question]

  def self.included(base)

  	# This block of code creates the following setters and getters
  	# en_name, es_name, en_note, es_note, etc. 
  	I18n.available_locales.each do |locale|
  	  ["to_label", "name", "note", "question"].each do |custom_method|
        define_method("#{locale}_#{custom_method}") do
          self.send(custom_method, locale)
        end
        
        define_method("#{locale}_#{custom_method}=") do |value|
          self.send(:set_translation, locale, custom_method, value)
        end
      end
    end
  
  end

  def snake_casify
  	 self.code = self.code.parameterize.underscore
  end

  # To Label is used by SimpleForm to Get the Label
  def to_label locale=I18n.default_locale
    self.name(locale)
  end

  def name locale=I18n.default_locale
    SimpleTranslationEngine.translate(locale, tkey_code(:name))
  end

  def note locale=I18n.default_locale
    SimpleTranslationEngine.translate(locale, tkey_code(:note))
  end

  def question locale=I18n.default_locale
    SimpleTranslationEngine.translate(locale, tkey_code(:question))
  end

  # set translations e.g.,  locale="en", object="name", value="medical"
  def set_translation(locale, translation, value)
    SimpleTranslationEngine.set_translation(locale, tkey_code(translation), value)
  end
  
  # Builds name, note, and question translation keys (not saved to db)
  def build_translation_keys
    TRANSLATION_TYPES.map do |t|
      TranslationKey.find_or_initialize_by(name: tkey_code(t))
    end
  end
  
  # Creates name, not, and question translation keys (saved to db)
  def create_translation_keys
    TRANSLATION_TYPES.map do |t|
      TranslationKey.find_or_create_by(name: tkey_code(t))
    end
  end
  
  # Builds a translation key code of the given type (e.g. :name)
  def tkey_code(t)
    "#{self.class.name.downcase}_#{self.code}_#{t}"
  end

end
