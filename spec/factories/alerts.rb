FactoryGirl.define do
  factory :alert do

  	factory :expired_alert do
      expiration Time.now - 2.weeks
    end

    user_emails_hash = {"user_emails" => "george@co.uk"}
    factory :alert_for_traveler do
      audience "specific_users"
      audience_details user_emails_hash
    end
    
  end
end
