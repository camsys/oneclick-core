
# Service object for translating OTP responses into preferred locale
class OTPTranslator
  
  attr_accessor :locale
  
  STEP_ATTRS_FOR_TRANSLATION = [ "relativeDirection", "absoluteDirection" ]
  
  def initialize(locale=I18n.default_locale, opts={})
    @locale = locale
  end
  
  # Translates an array of legs into the given locale
  def translate_legs(legs)
    return legs unless legs.is_a?(Array)
    legs.map { |leg| translate_leg(leg) }
  end
  
  # Translates an OTP Leg into the given locale
  def translate_leg(leg)
    steps = leg["steps"].is_a?(Array) ? leg["steps"] : []
    leg["steps"] = steps.map { |step| translate_step(step) }
    return leg
  end
  
  # Translates an OTP Step into the given locale
  def translate_step(step)
    step = step.is_a?(Hash) ? step : {}
    
    STEP_ATTRS_FOR_TRANSLATION.each do |attr|
      tkey = "otp.#{attr}.#{step[attr]}"
      
      # Only translate step attribute if a translation key exists for it
      if TranslationKey.find_by(name: tkey)
        step[attr] = SimpleTranslationEngine.translate(@locale, tkey)
      end
    end
    
    return step
  end
  
  
  
end
