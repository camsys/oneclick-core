FactoryGirl.define do
  factory :user do
    email "test_user@camsys.com"
    password "welcome1"
    password_confirmation "welcome1"
    first_name "Bob"
    last_name "Bobson"

    factory :admin do
      email "admin_user@camsys.com"
      after(:create) {|user| user.add_role("admin")}
    end

    factory :password_typo_user do
      password_confirmation "welcome2"
    end

  end
end
