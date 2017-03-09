FactoryGirl.define do
  factory :user do
    sequence(:email) {|i| "test_user_#{i}@camsys.com" }
    password "welcome1"
    password_confirmation "welcome1"
    first_name "Bob"
    last_name "Bobson"

    factory :admin do
      email "admin_user@camsys.com"
      after(:create) {|u| u.add_role("admin")}
    end

    factory :password_typo_user do
      password_confirmation "welcome2"
    end

    factory :english_speaker do
      email "george@co.uk"
      first_name "George"
      last_name "Williams"
      preferred_locale {create(:locale)}
<<<<<<< HEAD
    end 
=======
    end

    trait :needs_accommodation do
      after(:create) do |u|
        u.accommodations << create(:wheelchair)
        u.accommodations << create(:jacuzzi)
      end
    end

    trait :eligible do
      after(:create) do |u|
        u.user_eligibilities << create(:user_eligibility, :confirmed, user: u)
      end
    end

    trait :ineligible do
      after(:create) do |u|
        u.user_eligibilities << create(:user_eligibility, :denied, user: u)
      end
    end
>>>>>>> master

  end
end
