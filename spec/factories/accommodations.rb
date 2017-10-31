FactoryGirl.define do
  factory :accommodation do
    
    code "accommodation"

    factory :wheelchair do
      code "wheelchair"
    end

    factory :stretcher do
      code "stretcher"
    end

    factory :jacuzzi do
      code "jacuzzi"
    end
    
    initialize_with { Accommodation.find_or_create_by(code: code) }

    # Create translations for the accommodation
    trait :with_translations do
      after(:create) do |acc|      
        I18n.available_locales.each do |l|
          acc.set_translation(l, :name, "#{l} #{acc.code} name")
          acc.set_translation(l, :note, "#{l} #{acc.code} note")
          acc.set_translation(l, :question, "#{l} #{acc.code} question")
        end
      end
    end

  end
end
