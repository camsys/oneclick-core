class UsersController < ApplicationController

  def index
    @staff = User.all.order(:email)
  end

end