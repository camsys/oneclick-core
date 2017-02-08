class AdminController < ApplicationController

  before_action :confirm_permissions

  private

  def confirm_permissions
    
    #Check to see if we are logged in
    if current_user.nil?
      redirect_to new_user_session_path 
      return 
    end

    #Check to see if the logged-in user has permission
    unless can? :manage, :admin_features
      flash[:error] = "You do not have permission to access this function."
      redirect_to '/'  
      return 
    end

  end

end