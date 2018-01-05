FactoryBot.define do
  
  factory :ride_pilot_ambassador do
    skip_create
    
    initialize_with do
      opts = attributes[:opts] || { itinerary: create(:ride_pilot_itinerary)}
      RidePilotAmbassador.new(opts)
    end

  end

  factory :trapeze_ambassador do
    skip_create
    
    initialize_with do
      opts = attributes[:opts] || {}
      TrapezeAmbassador.new(opts)
    end

  end

end
