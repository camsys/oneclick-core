class Admin::ReportsController < Admin::AdminController
  
  def index
    @csv_download_tables = ['Trips', 'Users', 'Services']
    @dashboards = ['Planned Trips']
  end
  
  
  ### GRAPHICAL DASHBOARDS ###
  
  def dashboard
    params = dashboard_params
    dashboard_name = params[:dashboard_name].parameterize.underscore
    
    dashboard_url = self.send("#{dashboard_name}_dashboard_admin_reports_path")
    
    redirect_to dashboard_url
  end
  
  def planned_trips_dashboard
    @trips = Trip.all
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
    params.require(:dashboard).permit(:dashboard_name)
  end

end
