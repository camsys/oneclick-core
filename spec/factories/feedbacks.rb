FactoryGirl.define do
  factory :feedback do
    user
    comment "Pretty good, would use again."
    rating 4
    
    factory :service_feedback do
      association :feedbackable, factory: :service
    end
    
  end
end
