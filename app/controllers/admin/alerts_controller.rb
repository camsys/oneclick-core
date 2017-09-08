class Admin::AlertsController < Admin::AdminController

  load_and_authorize_resource

  def index
    @alerts = Alert.current
    @new_alert = Alert.new
  end

  def expired
    @alerts = Alert.expired
  end

  def destroy
    @alert.destroy
    redirect_to admin_alerts_path
  end

  def create
  	@alert.update_attributes(alert_params)
    missing_users_message = nil
    if @alert.audience == "specific_users"
      missing_users_message = @alert.handle_specific_users alert_params["audience_details"]
    end
    translations = params[:alert]
    translations.each do |translation, value|
      @alert.set_translation(translation.split('_').first, translation.split('_').last, value)
    end

    if missing_users_message.nil?
      flash[:success] = "Alert Created #{missing_users_message}"
    else
      flash[:warning] = "Alert Created, however no users were found for the following emails: #{missing_users_message}"
    end
  	redirect_to admin_alerts_path

  end

  def edit
  end

  def update
    redirect_to admin_alerts_path
  end

  private

  def alert_params
  	params.require(:alert).permit(:expiration, :published, :audience, audience_details: [:user_emails])
  end
  
end