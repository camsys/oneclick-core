class Admin::UsersController < Admin::AdminController

  # before_action :initialize_user, only: [:index, :create]
  authorize_resource
  before_action :load_user
  before_action :load_staff

  def index
  end

  def create
    create_params = user_params
    create_params.delete(:admin)
    role = create_params.delete(:roles)
    staff_agency = create_params.delete(:staff_agency)
    @user.assign_attributes(create_params)

    # Quick check to make sure we're not assigning a role to a traveler
    # unless we're a superuser
    if params[:is_traveler].nil?
      set_user_role(role, staff_agency)
    end

  	if @user.save
      flash[:success] = "Created #{@user&.first_name} #{@user&.last_name} as #{@user.roles.last&.name || "traveler"}"
      respond_to do |format|
        format.js
        format.html {redirect_to staff_admin_users_path}
      end
    else
      present_error_messages(@user)
      respond_to do |format|
        format.html {render :index}
      end
    end

  end

  def destroy
    redirect_path = @user.admin_or_staff? ? staff_admin_users_path : travelers_admin_users_path
    @user.destroy
    flash[:success] = "#{@user&.first_name} #{@user&.last_name} Deleted"
    redirect_to redirect_path
  end

  def edit
  end

  def travelers
    if current_user.superuser?
      @travelers = User.travelers
    elsif current_user.transportation_admin? || current_user.transportation_staff?
      @travelers = current_user.travelers_for_staff_agency
    elsif current_user.currently_oversight?
      @travelers = current_user.travelers_for_oversight_agency
    else
      @travelers = current_user.travelers_for_agency(current_user.current_agency)
    end
  end

  def staff
    # If the current user is a superuser
    if current_user.superuser?
      @staff = User.any_role
    # else if the current user is currently browsing as the oversight admin/ staff
    # - then see all oversight staff/admin AND associated transportation agency staff/admin
    elsif current_user.currently_oversight?
      oa = current_user.staff_agency
      tas = TransportationAgency.where(id:oa.agency_oversight_agency.pluck(:transportation_agency_id))
      @staff = User.any_staff_admin_for_agencies([oa] + tas)
    # else if the current user is currently browsing as a transportation agency
    elsif current_user.currently_transportation?
      @staff = User.any_staff_admin_for_agency(current_user.current_agency)
    # otherwise the current user is probably transportation staff
    else
      @staff = User.any_staff_admin_for_agency(current_user.staff_agency)
    end
  end

  def update

    success_redirect_path = @user.admin_or_staff? ? staff_admin_users_path : travelers_admin_users_path
    error_redirect_path = edit_admin_user_path(@user)

    #We need to pull out the password and password_confirmation and handle them separately
    update_params = user_params
    password = update_params.delete(:password)
    roles = update_params.delete(:roles)
    staff_agency = update_params.delete(:staff_agency)
    password_confirmation = update_params.delete(:password_confirmation)
    if roles != '' && staff_agency != ''
      # NOTE: THIS REMOVES THE LAST USER ROLE, THEN ADDS THE NEW ROLE
      # - IF USERS ARE ABLE TO HAVE MULTIPLE ROLES AT SOME POINT, THIS WILL NEED UPDATING
      replace_user_role(roles,staff_agency)
    end
    unless password.blank?
      @user.update_attributes(password: password, password_confirmation: password_confirmation)
    end

    @user.update_attributes(update_params)


    if @user.errors.empty?
      flash[:success] = "#{@user.first_name} #{@user.last_name} Updated"
      redirect_path = success_redirect_path
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
    agency = Agency.find(params[:agency][:id])
    if !agency.nil?
      current_user.current_agency = agency
      current_user.save!
    end

    redirect_back(fallback_location: root_path)
  end
  private
  def set_user_role(role, agency_id)
    ag = agency_id != '' ? Agency.find_by(id:agency_id) : nil
    User.transaction do
      # If the user can read the selected agency and manage roles
      # then assign the input role and agency to the user
      if (can? :read, ag) && (can? :manage, Role)
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
      if (can? :read, ag || ag.nil?) && (can? :manage, Role)
        last_role = @user.roles.last
        @user.remove_role(last_role.name,last_role.resource)
        @user.set_role(role, ag)
      else
        raise ActiveRecord::Rollback
      end
      raise ActiveRecord::Rollback unless @user.valid?
    end
  end

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
      :roles,
      :staff_agency,
      :is_traveler
    )
  end

end
