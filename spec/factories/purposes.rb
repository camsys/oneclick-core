FactoryGirl.define do
  factory :purpose do

    code 'medical'

    factory :metallica_concert do
      code "metallica_concert"
    end

    initialize_with { Purpose.find_or_create_by(code: code) }

  end
end
