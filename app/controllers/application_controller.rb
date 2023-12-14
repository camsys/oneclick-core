class ApplicationController < ActionController::Base
  
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :get_agencies
  helper_method :can_access_all?
    
  # If user is not authorized to visit a page, go the the root url and show a message
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { head :forbidden }
      format.js   { redirect_to main_app.root_url, alert: exception.message, status: :unauthorized }
      format.html { redirect_to main_app.root_url, alert: exception.message, status: :unauthorized }
    end
  end
  
  
  # Wrapper method calls can_access_all? on current ability
  def can_access_all?(model_class)
    current_ability.can_access_all?(model_class)
  end

  def get_agencies
    if current_user.nil?
      return
    end

    @agency_map = []
    if current_user.superuser?
      @agency_map = Agency.order(:name).pluck :name, :id
    elsif current_user.oversight_admin? || current_user.oversight_staff?
      ag_ids = [current_user.staff_agency.id].concat(current_user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id))
      @agency_map = Agency.where(id:ag_ids).order(:name).pluck(:name,:id)
    elsif current_user.transportation_admin? || current_user.transportation_staff?
      ag_ids = [current_user.staff_agency.id]
      @agency_map = Agency.where(id:ag_ids).order(:name).pluck(:name,:id)
    end
  end
  private

  # Allow additional sign_up parameters beyond email, password
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:last_name, :first_name])
  end

  def confirm_admin
    
    #Check to see if we are logged in
    if current_user.nil?
      redirect_to new_user_session_path 
      return 
    end

    #Check to see if the logged-in user has permission
    # unless can? :manage, :admin_features
    #   flash[:danger] = "You do not have permission to access this function."
    #   redirect_to '/'  
    #   return 
    # end

  end

  def in_travel_patterns_mode?
    Config.dashboard_mode.to_sym == :travel_patterns
  end

end
