module EligibilityAccommodationHelper

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

end
