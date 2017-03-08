FactoryGirl.define do
  factory :region do

    # Create geography records to build this region from
    before(:create) do
      create(:county)
    end

    recipe do
      {counties: [attributes_for(:county)]}
    end

  end
end
