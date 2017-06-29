FactoryGirl.define do
  factory :user, aliases: [:commenter] do
    sequence(:email) {|i| "test_user_#{i}@camsys.com" }
    password "welcome1"
    password_confirmation "welcome1"
    first_name "Test"
    last_name "McUser"

    factory :admin do
      email "admin_user@camsys.com"
      after(:create) {|u| u.add_role("admin")}
    end

    factory :another_admin do 
      email "another_admin_user@camsys.com"
      after(:create) {|u| u.add_role("admin")}
    end
    
    trait :staff do
      transient do
        staff_agency nil
      end
      
      after(:create) do |u, params|
        u.add_role(:staff, params.staff_agency)
      end
    end

    factory :password_typo_user do
      password_confirmation "welcome2"
    end

    factory :english_speaker do
      email "george@co.uk"
      first_name "George"
      last_name "Williams"
      preferred_locale {create(:locale)}
      preferred_trip_types ['transit', 'unicycle']
    end

    factory :guest do
      first_name "Guest"
      last_name "User"
      sequence(:email) {|i| "guest_user_#{i}@#{GuestUserHelper.new.email_domain}" } 
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

    trait :not_a_veteran do 
      after(:create) do |u|
        u.user_eligibilities << create(:answered_veteran, :denied, user: u)
      end
    end

    trait :ineligible do
      after(:create) do |u|
        u.user_eligibilities << create(:user_eligibility, :denied, user: u)
      end
    end
    
    trait :with_trip_today do
      after(:create) do |u|
        u.trips << create(:trip, trip_time: Date.today)
      end
    end
    
    trait :with_old_trip do
      after(:create) do |u|
        u.trips << create(:trip, trip_time: Date.today - 2.months)
      end
    end

  end
end
