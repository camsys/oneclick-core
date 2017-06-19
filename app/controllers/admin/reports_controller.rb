class Admin::ReportsController < Admin::AdminController
  
  DOWNLOAD_TABLES = ['Trips', 'Users', 'Services']
  DASHBOARDS = ['Planned Trips']
  GROUPINGS = [:hour, :day, :week, :month, :quarter, :year]
  
  # sets @from_date and @to_date instance variables from params
  before_action :set_filters, only: [
    :planned_trips_dashboard, 
    :trips_table, 
    :users_table, 
    :services_table
  ]
  
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
    @grouping = params[:grouping]

    @trips = Trip.from_date(@from_date).to_date(@to_date)
  end
  

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
    @users = @users.joins(:trips).merge(Trip.from_date(@user_active_from_date)) if @user_active_from_date
    @users = @users.joins(:trips).merge(Trip.to_date(@user_active_to_date)) if @user_active_to_date
    
    respond_to do |format|
      format.csv { send_data @users.to_csv }
    end
  end
  
  def trips_table
    @trips = Trip.from_date(@trip_time_from_date).to_date(@trip_time_to_date)
    # @trips = 
    
    respond_to do |format|
      format.csv { send_data @trips.to_csv }
    end
  end

  def services_table
    @services = Service.all
    
    respond_to do |format|
      format.csv { send_data @services.to_csv }
    end
  end
  
  protected
  
  def set_filters
    
    # TRIP FILTERS
    @trip_time_from_date = parse_date_param(params[:trip_time_from_date])
    @trip_time_to_date = parse_date_param(params[:trip_time_to_date])
    @trip_origin_region = Region.build(recipe: params[:trip_origin_recipe]) 
    @trip_destination_region = Region.build(recipe: params[:trip_destination_recipe]) 
    
    # USER FILTERS
    @include_guests = params[:include_guests].to_i == 1
    @accommodations = params[:accommodations].to_a.select {|a| !a.blank? }.map(&:to_i)
    @eligibilities = params[:eligibilities].to_a.select {|e| !e.blank? }.map(&:to_i)
    @user_active_from_date = parse_date_param(params[:user_active_from_date])
    @user_active_to_date = parse_date_param(params[:user_active_to_date])
    
    # SERVICE FILTERS
  end
  
  def download_table_params
    params.require(:download_table).permit(
      :table_name, 
      
      # TRIP FILTERS
      :trip_time_from_date, 
      :trip_time_to_date,
      :trip_origin_recipe,
      :trip_destination_recipe,
      
      # USER FILTERS
      :include_guests,
      {accommodations: []},
      {eligibilities: []},
      :user_active_from_date,
      :user_active_to_date
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

end
