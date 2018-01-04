# Service object for rendering dashboard reports based on config variables
# To define a new report type, add its name to the REPORT_TYPES array, (e.g. :report_name)
# and define a private method called "report_name_html" that returns HTML based on the @params hash
class DashboardReport
  
  # Expose a class variable for containing recipes for prebuilt reports.
  cattr_accessor :prebuilt_reports
  # Reports are stored in a hash, with the key being the name of the report,
  # and the value being an array of the params that will be passed to 
  # DashboardReport.new() to build that report.
  self.prebuilt_reports ||= {}
  
  include Chartkick::Helper
  
  # List of valid report types. Will not attempt to build reports with names not in this list.
  REPORT_TYPES = [
    :planned_trips,
    :unique_users,
    :popular_destinations,
    :popular_requests
  ]
  
  # Default formatting options to pass to chartkick calls as the :library option
  DEFAULT_CHART_OPTIONS = {
    chartArea: { width: '90%', height: '75%' },
    vAxis: { format: '#' }
  }
  
  def initialize(report_type=nil, params={})
    @report_type = report_type.try(:to_sym)
    @params = params
  end

  # Builds google chart html, based on report type
  def html
    REPORT_TYPES.include?(@report_type) ? self.send("#{@report_type}_html") : nil
  end
  
  # Returns true/false if the report can actually be rendered
  def valid?
    html.present?
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
  
  
  private
  
  ### REPORT BUILDER METHODS ###
  
  # Builds the html for a planned trips report, based on the passed params
  def planned_trips_html
    trips = @params[:trips] || Trip.all
    grouping = @params[:grouping] || :month
    grouped_trips = trips.send("group_by_#{grouping}", :trip_time, date_grouping_options(grouping)).count
    return column_chart(grouped_trips,
      id: "trips-planned-by-#{grouping}",
      title: @params[:title] || "Trips Planned by #{grouping.to_s.titleize}",
      library: DEFAULT_CHART_OPTIONS)
  end
  
  # Builds the html for a unique users report, based on the passed params
  def unique_users_html
    user_requests = @params[:user_requests] || RequestLog.all
    grouping = @params[:grouping] || :month
    grouped_user_requests = user_requests.send("group_by_#{grouping}", :created_at, date_grouping_options(grouping))
                                         .distinct.count(:auth_email)
    return column_chart(grouped_user_requests,
      id: "unique-users-by-#{grouping}",
      title: @params[:title] || "Unique Users by #{grouping.to_s.titleize}",
      library: DEFAULT_CHART_OPTIONS)
  end
  
  # Builds the html for a popular requests report, based on the passed params
  def popular_requests_html
    requests = @params[:requests] || RequestLog.all
    grouping_param = @params[:grouping_param]
    grouped_requests = @params[:requests]
                        .pluck(:params)
                        .map {|p| p.with_indifferent_access[grouping_param] }
                        .compact
                        .group_by(&:titleize)
                        .map { |k,v| [k, v.count] }.to_h
    return pie_chart(grouped_requests,
      id: "popular-requests-by-#{grouping_param}",
      title: @params[:title] || "Popular Requests by #{grouping_param.to_s.titleize}",
      library: DEFAULT_CHART_OPTIONS)
  end
  
  # Builds the html for a popular destinations report, based on the passed params
  def popular_destinations_html
    trips = @params[:trips] || Trip.all
    limit = @params[:limit] || 10
    destinations = Waypoint.where(id: trips.pluck(:destination_id))
                           .where.not(lat: nil, lng: nil)
                           .group(:lat, :lng, :name).count
                           .sort_by {|k,v| v }.reverse.take(limit).to_h
                           .map { |k,v| k.last.present? ? [k.last,v] : ["#{k[0]}, #{k[1]}",v] }.to_h    
    return pie_chart(destinations,
      id: "popular-destinations",
      title: "Popular Trip Destinations",
      library: DEFAULT_CHART_OPTIONS)
  end
  
  ### /report builder methods
  
  
  # Formats date groupings for a column chart, based on type of grouping
  def date_grouping_options(grouping)
    {
      format: {
          "day" => "%m/%d",
          "day_of_week" => "%a",
          "month_of_year" => "%b"
      }[grouping.to_s]
    }
  end
  
end
