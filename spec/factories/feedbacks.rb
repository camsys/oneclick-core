FactoryBot.define do
  factory :feedback do
    user
    review { "Pretty good, would use again." }
    rating { 4 }
    acknowledged { false }
    email { "contact@email.com" }
    phone { "555-555-5555" }
    
    factory :service_feedback do
      association :feedbackable, factory: :service
    end
    
    trait :pending do
      acknowledged { false }
    end
    
    trait :acknowledged do
      acknowledged { true }
      association :acknowledgement_comment, factory: :acknowledgement_comment
    end
    
    trait :anonymous do
      user { nil }
    end
    
    
  end
end
