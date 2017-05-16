class Admin::ReportsController < Admin::AdminController
  
  def index
    puts "REPORTS INDEX"
  end
  
  def download_csv
    download_url = self.send("#{params[:download_csv][:table_name].downcase}_admin_reports_path") + ".csv"
    
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

end
