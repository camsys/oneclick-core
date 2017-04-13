FactoryGirl.define do

  # FareCalculator
  factory :fare_calculator, class: FareHelper::FareCalculator do
    skip_create

    initialize_with do
      fare_structure = attributes[:fare_structure] || nil
      fare_details = attributes[:fare_details] || {}
      trip = attributes[:trip] || FactoryGirl.build(:guest_trip)
      options = attributes[:options] || {}
      new(fare_structure, fare_details, trip, options)
    end

  end

  # HTTPRequestBundler
  factory :http_request_bundler, class: HTTPRequestBundler do
    skip_create
  end

  # OTPAmbassador
  factory :otp_ambassador, class: OTPAmbassador do
    skip_create

    initialize_with do
      trip = attributes[:trip] || FactoryGirl.build(:guest_trip)
      trip_types = attributes[:trip_types] || Trip::TRIP_TYPES
      http_request_bundler = attributes[:http_request_bundler] || FactoryGirl.create(:http_request_bundler)
      new(trip, trip_types, http_request_bundler)
    end
  end

end
