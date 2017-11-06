
# Service object for translating OTP responses into preferred locale
class OTPTranslator
  
  attr_accessor :locale
  
  STEP_ATTRS_FOR_TRANSLATION = [ "relativeDirection", "absoluteDirection" ]
  
  def initialize(locale=I18n.default_locale, opts={})
    @locale = locale
  end
  
  # Translates an array of legs into the given locale
  def translate_legs(legs)
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
      step[attr] = SimpleTranslationEngine.translate(@locale, "otp.#{attr}.#{step[attr]}")
    end
    
    return step
  end
  
  
  
end
