class Admin::AlertsController < Admin::AdminController

  load_and_authorize_resource

  def index
    @alerts = Alert.current
    @new_alert = Alert.new
  end

  def expired
    @alerts = Alert.expired
  end

  def create
  	@alert.update_attributes(alert_params)
  	redirect_to admin_alerts_path
  end

  def edit
  end

  def update
    #translations = params[:accommodation]
    #translations.each do |translation, value|
    #  @accommodation.set_translation(translation.split('_').first, translation.split('_').last, value)
    #end
    #flash[:success] = "Translations Updated"
    redirect_to edit_admin_alert_path(@alert)
  end

  private

  def alert_params
  	params.require(:alert).permit(:subject, :message, :expiration)
  end
  
end