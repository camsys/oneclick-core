class UsersController < AdminController

  def index
    @staff = User.all.order(:email)
  end

end