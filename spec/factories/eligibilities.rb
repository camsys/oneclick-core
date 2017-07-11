FactoryGirl.define do
  factory :eligibility do

    code 'over_65'

    factory :veteran do
      code "veteran"
    end

    initialize_with { Eligibility.find_or_create_by(code: code) }

  end
end
