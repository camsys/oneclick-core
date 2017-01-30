FactoryGirl.define do
  factory :trip do
    user
    association :origin, factory: :place
    association :destination, factory: :place
  end
end
