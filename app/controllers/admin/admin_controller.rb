class Admin::AdminController < ApplicationController
  
  include AdminHelpers

  before_action :confirm_admin
  before_action :get_admin_pages
  
  helper_method :can_access_all?

  def index
  end

  # Wrapper method calls can_access_all? on current ability
  def can_access_all?(model_class)
    current_ability.can_access_all?(model_class)
  end

end
