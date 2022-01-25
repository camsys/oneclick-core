class Admin::UsersController < Admin::AdminController

  # before_action :initialize_user, only: [:index, :create]
  authorize_resource
  before_action :load_user

  def index
  end
  #
  def create
    redirect_path = params[:is_traveler].nil? ? staff_admin_users_path : travelers_admin_users_path
    create_params = user_params
    role = create_params.delete(:roles)
    staff_agency = create_params.delete(:staff_agency)
    @user.assign_attributes(create_params)

    # Quick check to make sure we're not assigning a role to a traveler
    # unless we're a superuser
    if params[:is_traveler].nil?
      if staff_agency.empty? && role != 'superuser'
        @user.errors.add(:agency, 'cannot be empty for non-superuser level users. Please choose an agency to assign to this user.')
      else
        set_user_role(role, staff_agency)
      end
    end

  	if @user.errors.empty? && @user.save
      flash[:success] = "Created #{@user&.first_name} #{@user&.last_name} as #{@user.roles.last&.name || "traveler"}"
      respond_to do |format|
        format.js
        format.html {redirect_to redirect_path}
      end
    else
      present_error_messages(@user)
      respond_to do |format|
        format.html {redirect_to redirect_path}
      end
    end

  end

  def destroy
    redirect_path = @user.admin_or_staff? || @user.superuser? ? staff_admin_users_path : travelers_admin_users_path
    @user.destroy
    flash[:success] = "#{@user&.first_name} #{@user&.last_name} Deleted"
    redirect_to redirect_path
  end

  def edit
  end

  def travelers
    @travelers = current_user.get_travelers_for_staff_user
  end

  def staff
    # If the current user is a superuser return users with role
    if current_user.superuser?
      @staff = User.any_role
      # Else if the current user is currently viewing as an oversight agency, return both oversight users
      # and users for all agencies currently under that oversight agency
    elsif current_user.currently_oversight?
      @staff = current_user.get_admin_staff_for_staff_user
    elsif current_user.currently_transportation?
      @staff = current_user.any_users_for_current_agency
      # else if the current user decides to view as an unaffiliated user
    else
      @staff = current_user.any_users_for_staff_agency.order(:last_name, :first_name, :email)
    end
  end

  def update
    success_redirect_path = (@user.admin_or_staff? || @user.superuser?) ? staff_admin_users_path : travelers_admin_users_path
    error_redirect_path = edit_admin_user_path(@user)

    #We need to pull out the password and password_confirmation and handle them separately
    update_params = user_params
    password = update_params.delete(:password)
    password_confirmation = update_params.delete(:password_confirmation)
    # Pulling out roles params separately
    roles = update_params.delete(:roles)
    staff_agency = update_params.delete(:staff_agency)


    # Update password attributes if they're included in request params
    unless password.blank?
      @user.update_attributes(password: password, password_confirmation: password_confirmation)
    end

    # Update other attributes
    @user.update_attributes(update_params)

    # If selected role isn't superuser and staff agency is empty, then add an error
    if roles.present? && roles != 'superuser' && staff_agency.blank?
      @user.errors.add(:agency, 'cannot be empty for non-superuser level users. Please choose an agency to assign to this user.')
    # Else update user roles if roles is present AND staff agency is present OR if role is superuser
    elsif (roles.present? && staff_agency.present?) || roles == 'superuser'
      # NOTE: THIS REMOVES THE LAST USER ROLE, THEN ADDS THE NEW ROLE
      # - IF USERS ARE ABLE TO HAVE MULTIPLE ROLES AT SOME POINT, THIS WILL NEED UPDATING
      replace_user_role(roles,staff_agency)
    end

    # If there are no user errors, return success
    if @user.errors.empty?
      flash[:success] = "#{@user.first_name} #{@user.last_name} Updated"
      redirect_path = success_redirect_path
    # Else present errors and redirect back
    else
      present_error_messages(@user)
      redirect_path = error_redirect_path
    end

    respond_to do |format|
      format.js
      format.html {redirect_to redirect_path}
    end

  end

  def change_agency
    agency = Agency.find_by(id:params[:agency][:id])
    current_user.current_agency = agency
    current_user.save!

    redirect_back(fallback_location: root_path)
  end

  private
  def set_user_role(role, agency_id)
    ag = agency_id.present? ? Agency.find_by(id:agency_id) : nil
    User.transaction do
      # If the user can read the selected agency and manage roles
      # then assign the input role and agency to the user
      if ((can? :show, ag) || ag.nil?) && (can? :manage, Role)
        @user.set_role(role, ag)
      else
        raise ActiveRecord::Rollback
      end
      raise ActiveRecord::Rollback unless @user.valid?
    end
  end

  def replace_user_role(role, agency_id)
    ag = agency_id != '' ? Agency.find_by(id:agency_id) : nil
    User.transaction do
      # If the user can read the selected agency and manage roles
      # then assign the input role and agency to the user
      if (can? :show, ag || ag.nil?) && (can? :manage, Role)
        last_role = @user.roles.last
        # If @user is an oversight user, then reset the current_agency_id field to null
        # This prevents strange interactions due to a potentially stale value in comparison to
        # the new non-oversight role
        if @user.oversight_user?
          @user.current_agency = nil
        end

        @user.remove_role(last_role.name,last_role.resource)
        @user.set_role(role, ag)
      else
        raise ActiveRecord::Rollback
      end
      raise ActiveRecord::Rollback unless @user.valid?
    end
  end

  # NOTE: Is the below dead code with the new agency restrictions/ role handling??
  # Set admin role on @user if current_user has permissions
  def set_superuser_role(admin_param)
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

  def user_params
  	params.require(:user).permit(
      :email,
      :first_name,
      :last_name,
      :password,
      :password_confirmation,
      :admin,
      :roles,
      :staff_agency,
      :is_traveler
    )
  end

end
