class Admin::ReportsController < Admin::AdminController
  
  CSV_DOWNLOAD_TABLES = ['Trips', 'Users', 'Services']
  DASHBOARDS = ['Planned Trips']
  GROUPINGS = [:day, :week, :month, :quarter, :year]
  
  def index
    @csv_download_tables = CSV_DOWNLOAD_TABLES
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
    @from_date = params[:from_date].blank? ? nil : Date.parse(params[:from_date])
    @to_date = params[:to_date].blank? ? nil : Date.parse(params[:to_date])

    @trips = Trip.from_date(@from_date).to_date(@to_date)
  end
  

  ### CSV TABLE DOWNLOADS ###
  
  def download_csv
    params = download_csv_params
    table_name = params[:table_name].parameterize.underscore
    
    table_url = self.send("#{table_name}_table_admin_reports_path") + ".csv"
    
    redirect_to table_url
  end
  
  def users_table
    @users = User.all
    
    respond_to do |format|
      format.csv { send_data @users.to_csv }
    end
  end
  
  def trips_table
    @trips = Trip.all
    
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
  
  def download_csv_params
    params.require(:download_csv).permit(:table_name, :from_date, :to_date)
  end
  
  def dashboard_params
    params.require(:dashboard).permit(:dashboard_name, :from_date, :to_date, :grouping)
  end

end
