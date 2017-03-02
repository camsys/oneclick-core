FactoryGirl.define do
  factory :eligibility do

    factory :medicare do
      code 'medicare'
    end

    factory :over_65 do
      code 'over_65'
    end

    factory :lycanthrope do
      code :lycanthrope
    end

  end
end
