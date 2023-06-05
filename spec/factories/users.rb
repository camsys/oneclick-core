FactoryBot.define do
  factory :user, aliases: [:commenter, :traveler] do
    sequence(:email) {|i| "test_user_#{rand(1000).to_s.rjust(3, "0")}_#{i}@camsys.com" }
    password { "camsysisgr8" }
    password_confirmation { "camsysisgr8" }
    first_name { "Test" }
    last_name { "McUser" }
    confirmed
    
    transient do
      staff_agency { nil }
    end

    trait :admin do
      after(:create) do |u, params|
        u.add_role(:admin, params.staff_agency)
      end
    end

    trait :staff do
      after(:create) do |u, params|
        u.add_role(:staff, params.staff_agency)
      end
    end

    factory :superuser do
      sequence(:email) {|i| "superuser_#{i}@camsys.com" }
      after(:create) {|u| u.add_role("superuser")}
    end

    trait :superuser do
      after(:create) {|u| u.add_role("superuser")}
    end

    factory :transportation_admin do
      sequence(:email) {|i| "admin_user_#{i}@camsys.com" }
      staff_agency {create(:transportation_agency)}
      admin
    end

    factory :another_admin do 
      email { "another_admin_user@camsys.com" }
      after(:create) {|u| u.add_role("admin")}
    end

    factory :oversight_admin do
      sequence(:email) {|i| "admin_user_#{i}@camsys.com" }
      staff_agency { create(:oversight_agency) }
      admin
    end
    
    factory :staff_user do
      sequence(:email) {|i| "staff_user_#{i}@camsys.com" }
      staff
    end
    
    factory :transportation_staff do
      sequence(:email) {|i| "staff_user_#{i}@camsys.com" }
      staff_agency { create(:transportation_agency) }
      staff
    end
    
    factory :partner_staff do
      sequence(:email) {|i| "staff_user_#{i}@camsys.com" }
      staff_agency { create(:partner_agency) }
      staff
    end

    factory :oversight_staff do
      sequence(:email) {|i| "staff_user_#{i}@camsys.com" }
      staff_agency { create(:oversight_agency) }
      staff
    end

    factory :password_typo_user do
      password_confirmation { "welcome2" }
    end

    factory :english_speaker do
      email { "george@co.uk" }
      first_name { "George" }
      last_name { "Williams" }
      preferred_locale {create(:locale_en)}
      preferred_trip_types { ['transit', 'unicycle'] }
    end
    
    factory :spanish_speaker do
      email { "hispanohablante@email.es" }
      first_name { "Hispano" }
      last_name { "Hablanto" }
      preferred_locale {create(:locale_es)}
      preferred_trip_types { ['transit', 'unicycle'] }
    end

    factory :guest do
      first_name { "Guest" }
      last_name { "User" }
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
    
    trait :with_booking_profiles do
      after(:create) do |u|
        u.booking_profiles << create(:ride_pilot_user_profile, user: u)
        u.booking_profiles << create(:ride_pilot_user_profile, user: u)
      end
    end
    
    trait :confirmed do
      confirmed_at { DateTime.current }
    end
    
    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_sent_at { DateTime.current - 10.days }
      confirmation_token { "bloop" }
    end

  end
end
