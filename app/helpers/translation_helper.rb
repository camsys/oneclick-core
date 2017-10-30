
module TranslationHelper
  
  def translate(key)
  	SimpleTranslationEngine.translate(@locale, key) # @locale is set in api_controller
  end

end
