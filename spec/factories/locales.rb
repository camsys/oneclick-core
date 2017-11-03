FactoryBot.define do
  factory :locale do
    name "en"
    
    factory :locale_en do
    end
    
    factory :locale_fr do
      name "fr"
    end
    
    factory :locale_es do
      name "es"
    end
    
    initialize_with { Locale.find_or_create_by(name: name) }

  end
  
end
