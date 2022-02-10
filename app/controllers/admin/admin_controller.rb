class Admin::AdminController < ApplicationController
  
  include AdminHelpers

  before_action :confirm_admin
  before_action :get_admin_pages
  before_action :allow_iframes
  before_action :build_homepage_charts, only: [:index]
  
  def index
    # Configure dashboard reports to display in an array of symbols under Config.dashboard_reports
    @dashboard_reports = !current_user.unaffiliated_user? && (Config.dashboard_reports || [])
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

  def build_homepage_charts
    # Return nil if the request isn't from the main dashboard homepage
    # - a bit hacky, but turns out this runs for all controllers in the admin namespace
    return nil unless params[:controller] == 'admin/admin'
    # If current user, then get trips for staff, otherwise fall back to all trips this week
    trips = current_user.get_trips_for_staff_user&.where(trip_time: DateTime.this_week) || Trip.where(trip_time: DateTime.this_week)
    relevant_auth_emails = current_user.get_travelers_for_staff_user&.pluck(:email)
                                       &.concat(current_user.get_admin_staff_for_staff_user&.pluck(:email))
    # Add some prebuilt reports for displaying on the homepage
    DashboardReport.prebuilt_reports.merge!({
                                              planned_trips_this_week: [
                                                :planned_trips,
                                                trips: trips,
                                                grouping: :day,
                                                title: "Trips Planned this Week"
                                              ],
                                              unique_users_this_week: [
                                                :unique_users,
                                                user_requests: RequestLog.where(
                                                  created_at: DateTime.this_week,
                                                  auth_email: relevant_auth_emails
                                                ),
                                                grouping: :day,
                                                title: "Unique Users this Week"
                                              ]
                                            })
  end
    
end
