class Admin::ReportsController < Admin::AdminController
  
  DOWNLOAD_TABLES = ['Trips', 'Users', 'Services', 'Requests']
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
    :requests_table
  ]  

  before_action :authorize_reports
  
  def index
    @download_tables = DOWNLOAD_TABLES
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
    @trips = Trip.from_date(@from_date).to_date(@to_date)
  end

  def unique_users_dashboard 
    @user_requests = RequestLog.from_date(@from_date).to_date(@to_date)
  end
  
  def popular_destinations_dashboard
    @trips = Trip.from_date(@from_date).to_date(@to_date)
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
  
  def users_table
    @users = User.all
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
    @trips = Trip.all
    @trips = @trips.from_date(@trip_time_from_date).to_date(@trip_time_to_date)
    @trips = @trips.with_purpose(@purposes) unless @purposes.empty?
    @trips = @trips.origin_in(@trip_origin_region.geom) unless @trip_origin_region.empty?
    @trips = @trips.destination_in(@trip_destination_region.geom) unless @trip_destination_region.empty?
    @trips = @trips.partner_agency_in(@partner_agency) unless @partner_agency.blank?
    
    respond_to do |format|
      format.csv { send_data @trips.to_csv }
    end
  end

  def services_table
    @services = Service.all
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
      format.csv { send_data @requests.to_csv }
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
    @partner_agency = params[:partner_agency].blank? ? nil : PartnerAgency.find(params[:partner_agency])
    
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
    
  end
  
  def set_dashboard_filters
    
    # DATE FILTERS
    @from_date = parse_date_param(params[:from_date])
    @to_date = parse_date_param(params[:to_date])
    @grouping = params[:grouping]
    
  end
  
  def download_table_params
    params.require(:download_table).permit(
      :table_name, 
      
      # TRIP FILTERS
      :trip_time_from_date, 
      :trip_time_to_date,
      :trip_origin_recipe,
      :trip_destination_recipe,
      {purposes: []},
      :partner_agency,
      
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
      :request_to_date
      
    )
  end
  
  def dashboard_params
    params.require(:dashboard).permit(
      :dashboard_name, 
      :from_date, 
      :to_date, 
      :grouping
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

end
