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
    
    if @alert.audience == "specific_users"
      @alert.handle_specific_users alert_params["audience_details"]
    end

    translations = params[:alert]
    translations.each do |translation, value|
      @alert.set_translation(translation.split('_').first, translation.split('_').last, value)
    end

  	redirect_to admin_alerts_path

  end

  def edit
  end

  def update
    @alert.update_attributes(alert_params)
    translations = params[:alert]
    translations.each do |translation, value|
      @alert.set_translation(translation.split('_').first, translation.split('_').last, value)
    end
    flash[:success] = "Alert Updated"
    redirect_to edit_admin_alert_path(@alert)
  end

  private

  def alert_params
  	params.require(:alert).permit(:expiration, :published, :audience, audience_details: [:user_emails])
  end
  
end