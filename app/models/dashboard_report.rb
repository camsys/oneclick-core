
# Service object for rendering dashboard reports based on config variables
class DashboardReport
  
  include Chartkick::Helper
  
  def initialize(report_type=nil, params={})
    @report_type = report_type.try(:to_sym)
    @params = params
  end
  
  # Builds google chart html, based on report type
  def html
    case @report_type
    when :planned_trips
      trips = @params[:trips]
      grouping = @params[:grouping]
      grouped_trips = trips.send("group_by_#{grouping}", :trip_time, date_grouping_options(grouping)).count
      
      return column_chart(
        grouped_trips,
        id: "trips-planned-by-#{grouping}",
        title: @params[:title] || "Trips Planned by #{grouping.to_s.titleize}",
        library: { vAxis: { format: '#' } }
      )
    when :unique_users
      user_requests = @params[:user_requests]
      grouping = @params[:grouping]
      grouped_user_requests = user_requests.send("group_by_#{grouping}", :created_at, date_grouping_options(grouping))
                                           .distinct.count(:auth_email)
      
      return column_chart(
        grouped_user_requests,
        id: "unique-users-by-#{grouping}",
        title: @params[:title] || "Unique Users by #{grouping.to_s.titleize}",
        library: { vAxis: { format: '#' } }
      )
    else
      return nil
    end
  end
  
  # Returns true/false if the report can actually be rendered
  def valid?
    html.present?
  end
  
  private
  
  # Groups a collection of trips data by trip time
  def trips_grouped_by_date(trips, grouping)
    trips.send("group_by_#{grouping}", :trip_time, date_grouping_options(grouping)).count
  end
  
  # Formats date groupings for a column chart, based on type of grouping
  def date_grouping_options(grouping)
    {
      format: {
          "day" => "%m/%d",
          "day_of_week" => "%a"
        }[grouping]
    }
  end
  
end
