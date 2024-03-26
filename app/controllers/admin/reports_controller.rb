class Admin::ReportsController < Admin::AdminController
  
  DOWNLOAD_TABLES = ['Trips', 'Users', 'Services', 'Requests', 'Feedback', 'Feedback Aggregated', 'Find Services']
  DASHBOARDS = ['Planned Trips', 'Unique Users', 'Popular Destinations']
  GROUPINGS = [:hour, :day, :week, :month, :quarter, :year, :day_of_week, :month_of_year]
  
  # Set filters on Dashboards
  before_action :set_dashboard_filters, only: [
    :planned_trips_dashboard,
    :unique_users_dashboard,
    :popular_destinations_dashboard
  ]
  
  # Set filters on CSV table downloads
  before_action :set_download_table_filters, only: [
    :trips_table, 
    :users_table, 
    :services_table,
    :requests_table,
    :feedback_table,
    :feedback_aggregated_table,
    :find_services_table
  ]  

  before_action :authorize_reports
  
  def index
    @download_tables = filter_download_tables
    @dashboards = DASHBOARDS
    @groupings = GROUPINGS
  end
    
  ### GRAPHICAL DASHBOARDS ###
  
  def dashboard
    params = dashboard_params
    dashboard_name = params[:dashboard_name].parameterize.underscore
    action_name = dashboard_name + "_dashboard"
    filters = params.except(:dashboard_name).to_h # Explicitly convert params to hash to avoid deprecation warning

    redirect_to({controller: 'reports', action: action_name}.merge(filters))
  end
  
  def planned_trips_dashboard
    @trips = current_user.get_trips_for_staff_user
    @trips = @trips.from_date(@from_date).to_date(@to_date)
    @trips = @trips.partner_agency_in(@partner_agency) unless @partner_agency.blank?
  end

  def unique_users_dashboard
    @user_requests = RequestLog.from_date(@from_date).to_date(@to_date)
    unless current_user.superuser?
      travelers_emails = current_user.get_travelers_for_staff_user.select(:email)
      @user_requests = @user_requests.where(auth_email: travelers_emails)
    end
  end
  
  def popular_destinations_dashboard
    @trips = current_user.get_trips_for_staff_user
    @trips = @trips.from_date(@from_date).to_date(@to_date)
  end
  
  ### / graphical dashboards
  

  ### CSV TABLE DOWNLOADS ###
  
  def download_table
    params = download_table_params
    table_name = params[:table_name].parameterize.underscore
    action_name = table_name + "_table"
    table_url = self.send("#{table_name}_table_admin_reports_path") + ".csv"
    filters = params.except(:table_name).to_h
    
    redirect_to({
      controller: 'reports', 
      action: action_name, 
      format: :csv
    }.merge(filters))
  end

  def filter_download_tables
    return DOWNLOAD_TABLES unless Config.dashboard_mode.to_sym == :travel_patterns

    DOWNLOAD_TABLES - ['Find Services', 'Feedback', 'Feedback Aggregated']
  end
  
  # TODO (Drew) Array addition is slow, plus we're sending multiple queries. This can be improved.
  def users_table
    if current_user.superuser?
      @users = User.all
    elsif current_user.transportation_admin? ||current_user.transportation_staff?
      @users = User.querify(current_user.any_users_for_staff_agency + current_user.travelers_for_staff_agency)
    elsif current_user.currently_oversight? || current_user.currently_transportation?
      @users = User.querify(current_user.any_users_for_current_agency + current_user.travelers_for_current_agency)
      # Fallback just in case an edge case is missed
    else
      @users = current_user.travelers_for_none
    end
    
    @users = @users.registered unless @include_guests
    @users = @users.with_accommodations(@accommodations) unless @accommodations.empty?
    @users = @users.with_eligibilities(@eligibilities) unless @eligibilities.empty?
    @users = @users.active_since(@user_active_from_date) if @user_active_from_date
    @users = @users.active_until(@user_active_to_date) if @user_active_to_date
    
    respond_to do |format|
      format.csv { send_data @users.to_csv }
    end
  end
  
  def trips_table
    # Initial scope limited by agency and role; consider narrowing this further if possible.
    @trips = current_user.get_trips_for_staff_user
  
    # Apply time range filtering as early as possible to reduce dataset size.
    @trips = @trips.from_date(@trip_time_from_date).to_date(@trip_time_to_date)
  
    # Filter by purpose, if specified.
    @trips = @trips.with_purpose(Purpose.where(id: @purposes).pluck(:name)) unless @purposes.empty?
  
    # Spatial queries optimization: Consider consolidating these into fewer database calls or adjusting logic to pre-filter.
    if @trip_origin_region.present?
      @trips = @trips.joins(:origin).where("ST_Within(waypoints.geom, ?)", @trip_origin_region.geom)
    end
  
    if @trip_destination_region.present?
      @trips = @trips.joins(:destination).where("ST_Within(waypoints.geom, ?)", @trip_destination_region.geom)
    end
  
    # Additional filters.
    @trips = @trips.oversight_agency_in(@oversight_agency) unless @oversight_agency.blank?
  
    # Filtering for trips created in 1click; adjust as needed.
    if @trip_only_created_in_1click
      @trips = @trips.joins(itineraries: :booking).where(itineraries: {trip_type: 'paratransit'}, bookings: {created_in_1click: true})
    end
  
    # Pre-load associations used in CSV generation to avoid N+1 queries.
    @trips = @trips.includes(:user, origin: [], destination: [], itineraries: [:booking])
  
    # Ordering and limiting the results to manage memory and speed.
    @trips = @trips.order(:trip_time).limit(CSVWriter::DEFAULT_RECORD_LIMIT)
  
    # Generate and send the CSV data.
    respond_to do |format|
      format.csv { send_data @trips.to_csv(limit: CSVWriter::DEFAULT_RECORD_LIMIT, in_travel_patterns_mode: in_travel_patterns_mode?) }
    end
  end
  

  def in_travel_patterns_mode?
    Config.dashboard_mode.to_sym == :travel_patterns
  end

  def feedback_table    
    @feedback = Feedback.all
    @feedback = @feedback.from_date(@trip_time_from_date).to_date(@trip_time_to_date)

    respond_to do |format|
      format.csv { send_data @feedback.to_csv }
    end
  end

  def feedback_aggregated_table   
    respond_to do |format|
      format.csv { send_data Feedback.aggregated_csv(@trip_time_from_date, @trip_time_to_date)}
    end
  end

  def find_services_table
    @find_services_histories = FindServicesHistory.all
    @find_services_histories = @find_services_histories.from_date(@created_at_from_date).to_date(@created_at_to_date)
    @find_services_histories = @find_services_histories.origin_in(@find_services_origin_recipe.geom) unless @find_services_origin_recipe.empty?
    respond_to do |format|
      format.csv { send_data @find_services_histories.to_csv }
    end
  end

  def services_table
    always_unaffiliated_services = Service.where(type: [:Uber,:Lyft,:Taxi])
    if current_user.superuser?
      @services = Service.all
    elsif current_user.transportation_admin? ||current_user.transportation_staff?
      @services = Service.where(agency_id: current_user.staff_agency.id).or(always_unaffiliated_services)
    elsif current_user.currently_oversight?
      sids = ServiceOversightAgency.where(oversight_agency_id: current_user.staff_agency.id).pluck(:service_id)
      @services = Service.where(id: sids).or(always_unaffiliated_services)
    elsif current_user.currently_transportation?
      @services = Service.where(agency_id: current_user.current_agency.id).or(always_unaffiliated_services)
      # Fallback just in case an edge case is missed
    elsif current_user.current_agency.nil?
      @services = Service.where(agency_id: nil).or(always_unaffiliated_services)
    else
      @services = Service.where(agency_id: current_user.staff_agency.id).or(always_unaffiliated_services)
    end
    @services = @services.where(type: @service_type) unless @service_type.blank?
    @services = @services.with_accommodations(@accommodations) unless @accommodations.empty?
    @services = @services.with_eligibilities(@eligibilities) unless @eligibilities.empty?
    @services = @services.with_purposes(@purposes) unless @purposes.empty?
    
    respond_to do |format|
      format.csv { send_data @services.to_csv }
    end
  end
  
  def requests_table
    @requests = RequestLog.from_date(@request_from_date).to_date(@request_to_date)
    
    respond_to do |format|
      format.csv { send_data @requests.to_csv(limit: CSVWriter::DEFAULT_RECORD_LIMIT) }
    end
  end
  
  ### / csv table downloads
  
  
  protected

  # Ensures that current_user has permission to view the reports
  def authorize_reports
    authorize! :read, :report
  end
  
  def set_download_table_filters
    
    # TRIP FILTERS
    @trip_time_from_date = parse_date_param(params[:trip_time_from_date])
    @trip_time_to_date = parse_date_param(params[:trip_time_to_date])
    @purposes = parse_id_list(params[:purposes])
    @trip_origin_region = Region.build(recipe: params[:trip_origin_recipe]) 
    @trip_destination_region = Region.build(recipe: params[:trip_destination_recipe])
    @oversight_agency = params[:oversight_agency].blank? ? nil : OversightAgency.find(params[:oversight_agency])
    @trip_only_created_in_1click = parse_bool(params[:trip_only_created_in_1click])
    # USER FILTERS
    @include_guests = parse_bool(params[:include_guests])
    @accommodations = parse_id_list(params[:accommodations])
    @eligibilities = parse_id_list(params[:eligibilities])
    @user_active_from_date = parse_date_param(params[:user_active_from_date])
    @user_active_to_date = parse_date_param(params[:user_active_to_date])
    
    # SERVICE FILTERS
    @service_type = params[:service_type]
    # @accommodations = parse_id_list(params[:accommodations])
    # @eligibilities = parse_id_list(params[:eligibilities])
    # @purposes = parse_id_list(params[:purposes])
    
    # REQUEST FILTERS
    @request_from_date = parse_date_param(params[:request_from_date])
    @request_to_date = parse_date_param(params[:request_to_date])

    # FIND SERVICES FILTERS
    @created_at_from_date = parse_date_param(params[:created_at_from_date])
    @created_at_to_date = parse_date_param(params[:created_at_to_date])
    @find_services_origin_recipe = Region.build(recipe: params[:find_services_origin_recipe])
    
  end
  
  def set_dashboard_filters
    
    # DATE FILTERS
    @from_date = parse_date_param(params[:from_date])
    @to_date = parse_date_param(params[:to_date])
    @grouping = params[:grouping]
    @partner_agency = params[:partner_agency].blank? ? nil : PartnerAgency.find(params[:partner_agency])
    
  end
  
  def download_table_params
    params.require(:download_table).permit(
      :table_name, 
      
      # TRIP FILTERS
      :trip_time_from_date, 
      :trip_time_to_date,
      :trip_origin_recipe,
      :trip_only_created_in_1click,
      :trip_destination_recipe,
      {purposes: []},
      :oversight_agency,
      
      # USER FILTERS
      :include_guests,
      {accommodations: []},
      {eligibilities: []},
      :user_active_from_date,
      :user_active_to_date,
      
      # SERVICE FILTERS
      :service_type,
      # {accommodations: []},
      # {eligibilities: []},
      # {purposes: []}
      
      # REQUEST FILTERS
      :request_from_date,
      :request_to_date,

      # FIND SERVICES FILTERS
      :created_at_from_date,
      :created_at_to_date,
      :find_services_origin_recipe
    )
  end
  
  def dashboard_params
    params.require(:dashboard).permit(
      :dashboard_name, 
      :from_date, 
      :to_date, 
      :grouping,
      :partner_agency
    )
  end
  
  # Parses date param, or returns nil if param is blank
  def parse_date_param(date_param)
    date_param.blank? ? nil : Date.parse(date_param)
  end
  
  # Parses a list of ids, removing blanks and converting to integers
  def parse_id_list(id_list_param)
    id_list_param.to_a.select {|el| !el.blank? }.map(&:to_i)
  end
  
  # Parses a boolean string, either "true", "false", "1", or "0"
  def parse_bool(bool_param)
    bool_param.try(:to_bool) || (bool_param.try(:to_i) == 1)
  end

  def filter_download_tables
    return DOWNLOAD_TABLES unless Config.dashboard_mode.to_sym == :travel_patterns

    DOWNLOAD_TABLES - ['Find Services', 'Feedback', 'Feedback Aggregated']
  end
end
