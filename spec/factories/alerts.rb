FactoryBot.define do
  factory :alert do

  	factory :expired_alert do
      expiration { Time.now - 2.weeks }
    end

    user_emails_hash = {"user_emails" => "george@co.uk"}
    factory :alert_for_traveler do
      audience { "specific_users" }
      audience_details { user_emails_hash }
    end
    
    # Create translations for the alert
    trait :with_translations do
      after(:create) do |a|      
        I18n.available_locales.each do |l|
          a.set_translation(l, :subject, "alert #{l} subject")
          a.set_translation(l, :message, "alert #{l} message")
        end
      end
    end
    
  end
end
