
# Service object for translating OTP responses into preferred locale
class OTPTranslator
  
  include OTPServices # For access to OTPResponse and OTPItinerary classes
  
  def initialize(opts={})
  end
  
  # Translates an itinerary into the passed locale
  def translate(itinerary, locale=I18n.default_locale)
    puts "TRANSLATING ITINERARY"
    legs = itinerary.legs.map {|l| OTPLeg.new(l) }
    puts legs.ai
  end
  
end
