
module TranslationHelper
  
  def translate(key)
  	SimpleTranslationEngine.translate(@traveler.nil? ? 'en' : @traveler.preferred_locale.name, key)
  end

end
