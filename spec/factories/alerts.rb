FactoryGirl.define do
  factory :alert do

  	factory :expired_alert do
      expiration Time.now + 2.weeks
    end
    
  end
end
