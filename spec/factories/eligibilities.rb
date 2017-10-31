FactoryGirl.define do
  factory :eligibility do

    code 'over_65'

    factory :veteran do
      code "veteran"
    end

    initialize_with { Eligibility.find_or_create_by(code: code) }
    
    # Create translations for the eligibility
    trait :with_translations do
      after(:create) do |elig|      
        I18n.available_locales.each do |l|
          elig.set_translation(l, :name, "#{l} #{elig.code} name")
          elig.set_translation(l, :note, "#{l} #{elig.code} note")
          elig.set_translation(l, :question, "#{l} #{elig.code} question")
        end
      end
    end

  end
end
