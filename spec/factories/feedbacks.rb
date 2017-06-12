FactoryGirl.define do
  factory :feedback do
    user
    review "Pretty good, would use again."
    rating 4
    
    factory :service_feedback do
      association :feedbackable, factory: :service
    end
    
  end
end
