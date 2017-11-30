class Admin::AdminController < ApplicationController
  
  include AdminHelpers

  before_action :confirm_admin
  before_action :get_admin_pages
  
  # Available Dashboard Reports for the Home Page
  DASHBOARD_REPORTS = {
    planned_trips_this_week: [  
      :planned_trips,
      trips: Trip.where(trip_time: DateTime.this_week),
      grouping: :day,
      title: "Trips Planned this Week"
    ],
    unique_users_this_week: [
      :unique_users,
      user_requests: RequestLog.where(created_at: DateTime.this_week),
      grouping: :day,
      title: "Unique Users this Week"
    ]
  }
  
  def index
    @dashboard_reports = (Config.dashboard_reports || [])
    .map { |rep| DashboardReport.new(*DASHBOARD_REPORTS[rep]) }
    .select { |rep| rep.valid? }
    
    puts @dashboard_reports.map(&:html)
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
