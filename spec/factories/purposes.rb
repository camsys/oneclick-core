FactoryBot.define do
  factory :purpose do

    code 'medical'

    factory :metallica_concert do
      code "metallica_concert"
    end

    initialize_with { Purpose.find_or_create_by(code: code) }
    
    # Create translations for the purpose
    trait :with_translations do
      after(:create) do |purp|      
        I18n.available_locales.each do |l|
          purp.set_translation(l, :name, "#{l} #{purp.code} name")
          purp.set_translation(l, :note, "#{l} #{purp.code} note")
          purp.set_translation(l, :question, "#{l} #{purp.code} question")
        end
      end
    end

  end
end
