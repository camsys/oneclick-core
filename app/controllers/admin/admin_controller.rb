class Admin::AdminController < ApplicationController
  
  include AdminHelpers

  before_action :confirm_admin
  before_action :get_admin_pages
  
  def index
    @dashboard_reports = get_dashboard_reports
  end
  
  private
  
  # Presents a flash message of errors attached to the given object
  def present_error_messages(record)
    error_msgs = (record.errors.try(:full_messages) || 
                  record.errors || 
                  []).to_sentence
    flash[:danger] = error_msgs unless error_msgs.empty?
  end
  
end
