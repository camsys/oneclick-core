class Admin::ReportsController < Admin::AdminController
  
  def index
    puts "REPORTS INDEX"
  end
  
  def users
    @users = User.all
    
    respond_to do |format|
      format.csv { send_data @users.to_csv(attributes: user_csv_attributes) }
    end
  end
  
  def user_csv_attributes
    [
      :email,
      :first_name,
      :last_name,
      :eligibilities
    ]
  end
  
end
