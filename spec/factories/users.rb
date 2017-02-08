FactoryGirl.define do
  factory :user do
    email "test_user@camsys.com"
    password "welcome1"
  
    factory :admin do
      email "admin_user@camsys.com"
      after(:create) {|user| user.add_role("admin")}
    end

  end
end
