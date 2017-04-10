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
      redirect_to admin_users_path
    else
      flash[:danger] = new_user.errors.first.join(' ') unless new_user.errors.empty?
      redirect_to admin_users_path #TODO: This will cause the form to be reset, we don't want that
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to admin_users_path
  end

  private

  def user_params
  	params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :roles)
  end

end