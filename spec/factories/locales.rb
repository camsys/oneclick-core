FactoryGirl.define do
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

  end
  
end
