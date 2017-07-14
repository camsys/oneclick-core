class MultidayTripPlanner < TripPlanner
  
  attr_accessor :trip_times
  
  def initialize(trip, trip_times=[], options={})
    puts "MULTI DAY TRIP PLANNER!"
    @trip_times = trip_times
    super(trip, options)
  end
  
  def plan
    prepare_ambassadors
    
    # get list of available services
    
    # for each trip time, create a trip, set @trip, plan a trip as normal, but start with available services as scope,
    # and only filter by schedule
    
  end
  
  def prepare_ambassadors
  end
  
  def available_services
  end
  
end
