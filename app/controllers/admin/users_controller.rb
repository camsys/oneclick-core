class Admin::UsersController < Admin::AdminController

  def index
    @staff = User.staff.order(:last_name, :first_name, :email)
    @new_user= User.new 
    @roles = Role.all
  end

  def create
  	roles = params[:user].delete :roles
  	role = Role.find_by(id: roles)
  	new_user = User.create(user_params)
  	role ? new_user.roles << role : nil
  	if new_user.errors.empty?
      flash[:success] = 'Created ' + new_user.email
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
    @user.update_attributes(update_params)
  end

  private

  def user_params
  	params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :roles)
  end

end
