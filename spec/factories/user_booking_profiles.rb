FactoryGirl.define do
  factory :user_booking_profile do
    user
    
    factory :ride_pilot_user_profile do
      service { create(:paratransit_service, :ride_pilot_bookable)}
      booking_api "ride_pilot"
      details {
        {
             :id => 0,
          :token => "RIDEPILOTTOKEN"
        }
      }
    end
  end
end
