# Provides helper methods for dealing with accommodations, 
# eligibilities, and purposes.
module CharacteristicsHelper

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
    SimpleTranslationEngine.translate(locale, "#{self.class.name.downcase}_#{self.code}_name")
  end

  def note locale=I18n.default_locale
    SimpleTranslationEngine.translate(locale, "#{self.class.name.downcase}_#{self.code}_note")
  end

  def question locale=I18n.default_locale
    SimpleTranslationEngine.translate(locale, "#{self.class.name.downcase}_#{self.code}_question")
  end

  # set translations e.g.,  locale="en", object="name", value="medical"
  def set_translation(locale, translation, value)
    SimpleTranslationEngine.set_translation(locale, "#{self.class.name.downcase}_#{self.code}_#{translation}", value)
  end

  # DEPRECATED -- done by serializers
  # def to_hash locale=:en
  #   {
  #     name: self.try(:name, locale),
  #     code: self.try(:code),
  #     note: self.try(:note, locale),
  #     question: self.try(:question, locale)
  #   }
  # end

end
