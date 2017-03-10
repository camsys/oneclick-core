FactoryGirl.define do
  factory :eligibility do

    code 'over_65'

    factory :veteran do
      code "veteran"
    end

  end
end
