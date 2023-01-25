FactoryBot.define do
  factory :config do
    initialize_with { Config.find_or_create_by(key: key) }
    key { "test_config" }
    value { "test" }

    factory :bool_config do
      key { "bool_config" }
      value { true }
    end

    factory :array_config do
      key { "array_config" }
      value { [1,"b",:c] }
    end

    factory :num_config do
      key { "num_config" }
      value { 3.1415 }
    end

    factory :otp_config do
      key { "open_trip_planner" }
      value { "http://fake-otp-url" } # We shouldn't be making external calls in spec
      # value "http://otp-ma.camsys-apps.com:8080/otp/routers/default"
    end

    factory :tff_config do
      key { "tff_api_key" }
      value { "test" } #"SIefr5akieS5"
    end

    factory :uber_token do 
      key { "uber_token" }
      value { "test" }
    end

    factory :lyft_client_token do 
      key { "lyft_client_token" }
      value { "test" }
    end
    
    factory :ride_pilot_url_config do
      key { "ride_pilot_url" }
      value { "http://ride-pilot.fake-url.com" }
    end
    
    factory :ride_pilot_token_config do
      key { "ride_pilot_token" }
      value { "FAKERIDEPILOTTOKEN" }
    end

    factory :trapeze_url_config do
      key { "trapeze_url" }
      value { "http://trapeze.fake-url.com" }
    end

    factory :trapeze_user_config do
      key { "trapeze_user" }
      value { "Trapeze" }
    end
    
    factory :trapeze_token_config do
      key { "trapeze_token" }
      value { "token" }
    end

    factory :dashboard_mode_config do
      key { "dashboard_mode" }
      value { "default" }
    end

    # TODO We'll have to set up two contexts of tests for this...
    # factory :dashboard_mode_config do
    #   key { "dashboard_mode" }
    #   value { "travel_patterns" }
    # end
    
  end
  
end
