class Admin::UsersController < Admin::AdminController

  def index
    @staff = User.all.order(:email)
  end

end