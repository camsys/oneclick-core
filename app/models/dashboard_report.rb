
# Service object for rendering dashboard reports based on config variables
class DashboardReport
  
  # Expose a class variable for containing recipes for prebuilt reports.
  cattr_accessor :prebuilt_reports
  # Reports are stored in a hash, with the key being the name of the report,
  # and the value being an array of the params that will be passed to 
  # DashboardReport.new() to build that report.
  self.prebuilt_reports ||= {}
  
  include Chartkick::Helper
  
  DEFAULT_CHART_OPTIONS = {
    chartArea: { width: '95%', height: '75%' },
    vAxis: { format: '#' }
  }
  
  def initialize(report_type=nil, params={})
    @report_type = report_type.try(:to_sym)
    @params = params
  end
  
  # Builds a DashboardReport object based on a predefined recipe
  def self.prebuilt(report_name)
    report_name = report_name.to_s.parameterize.to_sym
    if(self.prebuilt_reports.include?(report_name))
      return self.new(*self.prebuilt_reports[report_name])
    else
      return nil
    end
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
        library: DEFAULT_CHART_OPTIONS
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
        library: DEFAULT_CHART_OPTIONS
      )
    when :popular_requests
      requests = @params[:requests]
      grouping_param = @params[:grouping_param]
      grouped_requests = @params[:requests]
                          .pluck(:params)
                          .map {|p| p.with_indifferent_access[grouping_param] }
                          .group_by(&:titleize)
                          .map { |k,v| [k, v.count] }.to_h
      return pie_chart(
        grouped_requests,
        id: "popular-requests-by-#{grouping_param}",
        title: "Popular Requests by #{grouping_param.to_s.titleize}",
        library: DEFAULT_CHART_OPTIONS
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
