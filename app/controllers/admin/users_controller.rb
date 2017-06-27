class Admin::UsersController < Admin::AdminController
  
  before_action :load_user, only: [:destroy, :edit, :update]

  def index
    @staff = current_user.accessible_staff.order(:last_name, :first_name, :email)
    @new_user= User.new 
    @roles = Role::ROLES
  end

  def create
    create_params = user_params
    roles_attributes = create_params.delete(:roles_attributes)
    @new_user = User.create(create_params)
    @new_user.update_roles(roles_attributes) if roles_attributes.present?
    
  	if @new_user.errors.empty?
      flash[:success] = "Created #{@new_user.first_name} #{@new_user.last_name}"
    else
      flash[:danger] = @new_user.errors.first.join(' ') unless @new_user.errors.empty?
    end
    respond_to do |format|
      format.js
      format.html {redirect_to admin_users_path}
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
    roles_attributes = update_params.delete(:roles_attributes)
    
    @user.update_roles(roles_attributes) if roles_attributes.present?
    
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
  
  def load_user
    @user = User.find_by(id: params[:id])
  end

  def user_params
  	params.require(:user).permit(
      :email, 
      :first_name, 
      :last_name, 
      :password, 
      :password_confirmation, 
      roles_attributes: [
        :name,
        :resource_id,
        :resource_type,
        :id,
        :_destroy
      ]
    )
  end

end
