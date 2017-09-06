# Similar to TripPlanner, but plans a return trip with reverse directions,
# and with a selected itinerary from the same mode/service
class ReturnTripPlanner < TripPlanner
  attr_accessor :outbound_trip
  attr_accessor :outbound_trip_type
  attr_accessor :outbound_service
  
  # Pass the outbound trip, a hash of attributes for overwriting the default
  # return trip attributes, and a hash of options to be passed to the trip planner
  def initialize(outbound_trip, return_trip_attrs={}, options={})
    @outbound_trip = outbound_trip
    @outbound_trip_type = @outbound_trip.trip_type
    @outbound_service = @outbound_trip.selected_service
    return_trip = @outbound_trip.build_return_trip(return_trip_attrs)
    return_trip_opts = {
      trip_types: [@outbound_trip_type].compact,
      available_services: Service.where(id: @outbound_service.try(:id))
    }.merge(options)
    super(return_trip, return_trip_opts)
  end
  
  # After planning, select the (should be only) itinerary
  def plan
    super
    @trip.itineraries
         .find_by(trip_type: @outbound_trip_type, service: @outbound_service)
         .try(:select)
    @trip.save
    @trip
  end
  
end
