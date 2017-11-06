FactoryBot.define do
  factory :user_booking_profile do
    user
    
    factory :ride_pilot_user_profile do
      service { create(:paratransit_service, :ride_pilot_bookable)}
      booking_api "ride_pilot"
      details { { details: "MISCELLANEOUS DETAILS" } }
      external_user_id '0'
      external_password "RIDEPILOTTOKEN"
    end
  end
end
