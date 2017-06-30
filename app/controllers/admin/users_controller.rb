class Admin::UsersController < Admin::AdminController
  
  # before_action :initialize_user, only: [:index, :create]
  authorize_resource
  before_action :load_user
  before_action :load_staff

  def index
  end

  def create
    create_params = user_params
        
    # Update the user's roles as appropriate
    set_admin_role(create_params.delete(:admin))
    set_staff_role(create_params.delete(:staff_agency))
                  
    @user.assign_attributes(create_params)
    
  	if @user.save
      flash[:success] = "Created #{@user.first_name} #{@user.last_name}"
      respond_to do |format|
        format.js
        format.html {redirect_to admin_users_path}
      end
    else
      flash[:danger] = @user.errors.first.join(' ') unless @user.errors.empty?
      respond_to do |format|
        format.html {render :index}
      end
    end

  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.first_name} #{@user.last_name} Deleted"
    redirect_to admin_users_path
  end

  def edit
  end

  def update

    #We need to pull out the password and password_confirmation and handle them separately
    update_params = user_params
    password = update_params.delete(:password)
    password_confirmation = update_params.delete(:password_confirmation)
    
    # Update the user's roles as appropriate
    set_admin_role(update_params.delete(:admin))
    set_staff_role(update_params.delete(:staff_agency))
        
    unless password.blank?
      @user.update_attributes(password: password, password_confirmation: password_confirmation)
    end
    
    @user.update_attributes(update_params)

    if @user.errors.empty?
      flash[:success] = "#{@user.first_name} #{@user.last_name} Updated"
    else
      flash[:danger] = @user.errors.first.join(' ') 
    end

    respond_to do |format|
      format.js
      format.html {redirect_to admin_users_path}
    end

  end

  private
  
  # Set admin role on @user if current_user has permissions
  def set_admin_role(admin_param)
    return false if admin_param.nil?
    @user.set_admin(admin_param.to_bool) if can?(:manage, :admin)
  end
  
  # Set staff role on @user if current_user has permissions
  def set_staff_role(staff_agency_param)
    staff_agency_id = staff_agency_param.to_i
    staff_agency = Agency.find_by(id: staff_agency_id)
    
    # If staff_agency is present and the current_user can update it, set @user as staff for that agency
    if staff_agency
      if can? :update, staff_agency
        @user.set_staff_role(staff_agency)
      end
    else
      # If staff_agency is not present, and current_user can manage Agencies, set @user as staff for no agency
      if can? :manage, Agency
        @user.set_staff_role(nil)
      # If staff_agency is not present, and current_user cannot manage Agencies, set @user as staff for current_user's agency
      else
        @user.set_staff_role(current_user.staff_agency)
      end
    end
  end
  
  def load_user
    @user = User.find_by(id: params[:id]) || User.new
  end

  def load_staff
    @staff = current_user.accessible_staff.order(:last_name, :first_name, :email)
  end

  def user_params
  	params.require(:user).permit(
      :email, 
      :first_name, 
      :last_name, 
      :password, 
      :password_confirmation,
      :admin,
      :staff_agency
    )
  end

end
