FactoryGirl.define do
  factory :user_alert do
    
    alert { create(:alert, :with_translations) }
    user { create(:spanish_speaker)}
    
  end
end
