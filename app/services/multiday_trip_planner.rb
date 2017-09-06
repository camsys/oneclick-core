class MultidayTripPlanner < TripPlanner
  
  attr_accessor :trip_times, :trip_template, :trip_ids
  
  def initialize(trip_template, trip_times=[], options={})
    @trip_template = trip_template
    @trip_times = trip_times
    @trip_ids = []
    super(nil, options)
  end
  
  def plan
    # set base scope from which to identify available services
    set_master_service_scope
    
    # For each trip time, create a trip, set @trip, plan a trip as normal, 
    # but start with available services as scope, and only filter by schedule
    @trip_times.each do |datetime|
      @trip = @trip_template.dup
      @trip.trip_time = datetime
            
      set_available_services
      prepare_ambassadors
      
      build_all_itineraries
      @trip_ids << @trip.id if @trip.save
    end
    
    return trips
    
  end
  
  # Create a new set of ambassadors for each trip
  def prepare_ambassadors
    @router = OTPAmbassador.new(@trip, @trip_types, @http_request_bundler, @available_services[:transit])
    @taxi_ambassador = TFFAmbassador.new(@trip, @http_request_bundler, services: @available_services[:taxi])
    @uber_ambassador = UberAmbassador.new(@trip, @http_request_bundler)
  end
  
  # Set the available services scope to the master scope, filtered by schedule
  def set_available_services    
    @available_services = available_services_hash(
      @master_service_scope.available_for(@trip, only_by: [:schedule])
    ) 
  end
  
  # Set the master service scope to services filtered by everything but schedule
  def set_master_service_scope
    @master_service_scope = Service.published
                                   .by_trip_type(*@trip_types)
                                   .available_for(@trip_template, except_by: [:schedule])
  end
  
  # Returns a collection of trips created by the planner
  def trips
    Trip.where(id: @trip_ids)
  end
  
end
