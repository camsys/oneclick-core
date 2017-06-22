FactoryGirl.define do
  factory :accommodation do
    
    code "accommodation"

    factory :wheelchair do
      code "wheelchair"
    end

    factory :stretcher do
      code "stretcher"
    end

    factory :jacuzzi do
      code "jacuzzi"
    end
    
    initialize_with { Accommodation.find_or_create_by(code: code) }

  end
end
