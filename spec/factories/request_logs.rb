FactoryBot.define do
  factory :request_log do
    controller { "MyString" }
    action { "MyString" }
    params { "MyText" }
    auth_email { "MyString" }
    duration { 1 }
  end
end
