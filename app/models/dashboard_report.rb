
# Service object for rendering dashboard reports based on config variables
class DashboardReport
  
  include Chartkick::Helper
  
  def initialize(report_type, params={})
    @report_type = report_type.to_sym
    @params = params
  end
  
  # Builds google chart html, based on report type
  def html
    case @report_type
    when :planned_trips
      return column_chart(
        planned_trips_data(@params[:trips], @params[:grouping]), 
        {
          title: "Trips Planned by #{@params[:grouping]}",
          library: { vAxis: { format: '#' } }
        }
      )
    when :planned_trips_this_week
      return column_chart(
        planned_trips_data(Trip.where(trip_time: this_week), :day), 
        {
          title: "Trips Planned this Week",
          library: { vAxis: { format: '#' } }
        }
      )
    when :unique_users_this_week
      # return {
      #   partial: "admin/reports/unique_signins_chart",
      #   locals: {
      #     sign_ins: RequestLog.where(created_at: this_week),
      #     grouping: :day,
      #     title: "Unique Users this Week"
      #   }
      # }
    else
      return nil
    end
  end
  
  # Returns true/false if the report can actually be rendered
  def valid?
    html.present?
  end
  
  private
  
  # Returns a datetime range for the last 7 days
  def this_week
    (DateTime.current - 7.days)..DateTime.current
  end
  
  def planned_trips_data(trips, grouping)
    trips.send("group_by_#{grouping}", :trip_time, date_grouping_options(grouping)).count
  end
  
  def date_grouping_options(grouping)
    {
      format: {
          "day" => "%m/%d",
          "day_of_week" => "%a"
        }[grouping]
    }
  end
  
end
