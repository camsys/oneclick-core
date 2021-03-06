class ApplicationController < ActionController::Base
  
  before_action :configure_permitted_parameters, if: :devise_controller?
  
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


end
