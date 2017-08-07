FactoryGirl.define do
  factory :booking do
    itinerary
    
    factory :ride_pilot_booking, class: "RidePilotBooking" do
      type "RidePilotBooking"
      status "requested"
      confirmation "12345"
      details { {
             "trip_id" => 1554,
         "pickup_time" => "2017-08-13T07:09:00-06:00",
        "dropoff_time" => "2017-08-13T08:09:00-06:00",
            "comments" => nil,
              "status" => {
               "code" => "requested",
               "name" => "Requested",
            "message" => "Your trip request has been accepted."
            } 
          } }
    end
    
  end
end
