# Provides helper methods for dealing with accommodations, 
# eligibilities, and purposes.
module CharacteristicsHelper

  def self.included(base)

  	# This block of code creates the following helpers
  	# en_name, es_name, en_note, es_note, etc. 
  	I18n.available_locales.each do |locale|
  	  ["to_label", "name", "note", "question"].each do |custom_method|
        define_method("#{locale}_#{custom_method}") do
          self.send(custom_method, locale)
        end
      end
    end
  
  end

  def snake_casify
  	 self.code = self.code.parameterize.underscore
  end

  # To Label is used by SimpleForm to Get the Label
  def to_label locale=:en
    self.name locale
  end

  def name locale=:en
    SimpleTranslationEngine.translate(locale, "#{self.class.name.downcase}_#{self.code}_name")
  end

  def note locale=:en
    SimpleTranslationEngine.translate(locale, "#{self.class.name.downcase}_#{self.code}_note")
  end

  def question locale=:en
    SimpleTranslationEngine.translate(locale, "#{self.class.name.downcase}_#{self.code}_question")
  end

  # set translations e.g.,  locale="en", object="name", value="medical"
  def set_translation(locale, translation, value)
    SimpleTranslationEngine.set_translation(locale, "#{self.class.name.downcase}_#{self.code}_#{translation}", value)
  end

end
