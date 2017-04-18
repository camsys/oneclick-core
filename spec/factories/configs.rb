FactoryGirl.define do
  factory :config do
    initialize_with { Config.find_or_create_by(key: key) }

    key "test_config"
    value "test"

    factory :bool_config do
      key "bool_config"
      value true
    end

    factory :array_config do
      key "array_config"
      value [1,"b",:c]
    end

    factory :num_config do
      key "num_config"
      value 3.1415
    end

    factory :otp_config do
      key "open_trip_planner"
      value "http://otp-ma.camsys-apps.com:8080/otp/routers/default"
    end

    factory :tff_config do
      key "tff_api_key"
      value "test" #"SIefr5akieS5"
    end

    factory :uber_token do 
      key "uber_token"
      value "test"
    end
  end
end
