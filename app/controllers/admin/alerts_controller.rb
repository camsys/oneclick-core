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
    warnings = @alert.update alert_params
    if warnings.empty?
      flash[:success] = "Alert Created"
    else
      flash[:warning] = "Alert Created with Warnings: #{warnings}"
    end
    redirect_to admin_alerts_path
  end

  def edit
  end

  def update
    warnings = @alert.update alert_params
    if warnings.empty?
      flash[:success] = "Alert Updated"
    else
      flash[:warning] = "Alert Updated with Warnings: #{warnings}"
    end
    redirect_to admin_alerts_path
  end

  private

  def alert_params
    #Array of allowed translations
    permitted_translations = []
    I18n.available_locales.each do |locale|
      Alert::CUSTOM_TRANSLATIONS.each do |custom_method|
        permitted_translations << "#{locale}_#{custom_method}".to_sym
      end
    end

  	params.require(:alert).permit(:expiration, :published, :audience, translations: permitted_translations, audience_details: [:user_emails])
  end
  
end