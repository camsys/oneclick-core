FactoryGirl.define do
  
  factory :ride_pilot_ambassador do
    skip_create
    
    initialize_with do
      opts = attributes[:opts] || { itinerary: create(:ride_pilot_itinerary)}
      RidePilotAmbassador.new(opts)
    end

  end

end
