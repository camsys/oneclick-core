FactoryGirl.define do
  factory :comment do
    comment "Hello"
    locale "en"

    factory :es do
      comment "Hola"
      locale "es"
    end

    factory :fr do
      comment "Bonjour"
      locale "fr"
    end
    
    trait :with_commenter do
      commenter
    end
  end
end
