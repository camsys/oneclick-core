FactoryBot.define do
  factory :agency_type do
    factory :oversight_type, class: "AgencyType" do
      name { "OversightAgency" }
    end

    factory :partner_type, class: "AgencyType" do
      name { "PartnerAgency" }
    end

    factory :transportation_type, class: "AgencyType" do
      name { "TransportationAgency" }
    end
  end

end
