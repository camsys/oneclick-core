FactoryBot.define do
  factory :funding_source do
    sequence(:name) { |n| "Funding Source #{n}" }
    description { "MyString" }
    agency
  end
end
