class Admin::ReportsController < Admin::AdminController
  
  def index
    @csv_download_tables = ['Trips', 'Users', 'Services']
  end
  
  def download_csv
    params = download_csv_params
    table_name = params[:table_name].downcase
    
    download_url = self.send("#{table_name}_admin_reports_path") + ".csv"
    
    redirect_to download_url
  end
  
  def users
    @users = User.all
    
    respond_to do |format|
      format.csv { send_data @users.to_csv }
    end
  end
  
  def trips
    @trips = Trip.all
    
    respond_to do |format|
      format.csv { send_data @trips.to_csv }
    end
  end

  def services
    @services = Service.all
    
    respond_to do |format|
      format.csv { send_data @services.to_csv }
    end
  end
  
  protected
  
  def download_csv_params
    params.require(:download_csv).permit(:table_name, :from_date, :to_date)
  end

end
