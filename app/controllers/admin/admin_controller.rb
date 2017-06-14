class Admin::AdminController < ApplicationController
  
  include AdminHelpers

  before_action :confirm_admin
  before_action :get_admin_pages

  def index
  end

end
