class Admin::UsersController < Admin::AdminController

  def index
    @staff = User.staff.order(:last_name, :first_name, :email)
    @new_user= User.new 
    @roles = RoleHelper::ROLES
  end

  def create
  	roles = params[:user].delete :roles
  	role = Role.find_by(id: roles)
  	new_user = User.create(user_params)
  	role ? new_user.roles << role : nil
  	if new_user.errors.empty?
      flash[:success] = "Created #{new_user.first_name} #{new_user.last_name}"
    else
      flash[:danger] = new_user.errors.first.join(' ') unless new_user.errors.empty?
    end
    respond_to do |format|
      format.js
      format.html {redirect_to admin_users_path}
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    flash[:success] = "#{@user.first_name} #{@user.last_name} Deleted"
    redirect_to admin_users_path
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    #We need to pull out the password and password_confirmation and handle them separately
    update_params = user_params
    password = update_params.delete(:password)
    password_confirmation = update_params.delete(:password_confirmation)

    @user = User.find(params[:id])
    
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

  def user_params
  	params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :roles)
  end

end
