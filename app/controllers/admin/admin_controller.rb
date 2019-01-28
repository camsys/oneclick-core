class Admin::AdminController < ApplicationController
  
  include AdminHelpers

  before_action :confirm_admin
  before_action :get_admin_pages
  before_action :allow_iframes
  
  # Add some prebuilt reports for displaying on the homepage
  DashboardReport.prebuilt_reports.merge!({
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
  })
  
  def index
    # Configure dashboard reports to display in an array of symbols under Config.dashboard_reports
    @dashboard_reports = (Config.dashboard_reports || [])
    .map { |rep| DashboardReport.prebuilt(rep) }
    .compact
    .select { |rep| rep.valid? }
  end
  
  private
  
  # Presents a flash message of errors attached to the given object
  def present_error_messages(record)
    error_msgs = (record.errors.try(:full_messages) || 
                  record.errors || 
                  []).to_sentence
    flash[:danger] = error_msgs unless error_msgs.empty?
  end

  def allow_iframes
    response.headers.delete "X-Frame-Options"
  end
    
end
