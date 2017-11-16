module SamplesHelper
  
  class CharacteristicBuilder
    
    # initialize with a type symbol (:accommodation, :eligibility, :purpose)
    def initialize(char_type)
      @char_type = char_type.to_sym
      @model_class = @char_type.to_s.classify.constantize
    end
    
    # builds a characteristic given a hash with code, name, note, and question
    def build(char_hash)
      char = @model_class.find_or_create_by(code: char_hash.delete(:code))
      puts
      puts "*** Building #{@model_class.name}: #{char.code} ***"
      puts
      puts "Creating Translations:"
      
      char_hash.each do |tkey, tvalue|
        
        I18n.available_locales.each do |locale|
          tvalue = "#{locale}_#{tvalue}" unless locale == :en
          puts "#{char.code}_#{tkey} in #{locale}: #{tvalue}"
          char.set_translation(locale, tkey, tvalue)
        end
      end
      
      return char
    end
    
    # builds a an array of characteristics
    def build_all(char_hashes)
      char_hashes.map { |char_hash| build(char_hash) }
    end
    
  end
  
end
