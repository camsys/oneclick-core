FactoryBot.define do
  factory :agency do
    name "Test Transportation Agency"
    logo Rails.root.join("spec/files/mbta.png").open
    email "test_transportation_agency@oneclick.com"    
    phone "(555)555-5555"
    url "http://www.test-transportation-agency-url.gov"
    type "TransportationAgency"    
    # description "Wow, what an agency this is! People just talk and talk about how great this agency is because it's the best agency in the world. I could go on and on about it but you're probably busy. Really though. What a cool agency!"
    published
    association :agency_type
    
    factory :transportation_agency, class: "TransportationAgency" do
      association :agency_type, factory: :transportation_type
    end
    
    factory :partner_agency, class: "PartnerAgency" do
      name "Test Partner Agency"
      logo Rails.root.join("spec/files/parrot.gif").open
      email "test_partner_agency@oneclick.com"    
      phone "(555)555-5555"
      url "http://www.test-partner-agency-url.gov"
      type "PartnerAgency"
      association :agency_type, factory: :partner_type
    end
    
    trait :published do
      published true
    end
    
    trait :unpublished do
      published false
    end
    
    trait :with_services do
      after(:create) do |agency|
        agency.services << create(:paratransit_service)
        agency.services << create(:taxi_service)
        agency.services << create(:transit_service)
      end
    end
    
    trait :with_staff do
      after(:create) do |agency|
        agency.add_staff(create(:user))
        agency.add_staff(create(:user))
      end
    end
    
    trait :with_descriptions do
      after(:create) do |agency|
        I18n.available_locales.each do |loc|
          agency.send("#{loc}_description=", "#{loc.upcase} Description")
        end
      end
    end
    
  end
end
