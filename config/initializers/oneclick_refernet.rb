
# Only run this code if OneclickRefernet module is included
if ENV["ONECLICK_REFERNET"]  
  # Set the refernet API token
  # TODO: Make this configurable per client
  OneclickRefernet.api_token = '98ce0951e7ef475b86171fc075c9bac1'
   
  # Set the default radius for finding nearby services
  OneclickRefernet.default_radius_meters = (ENV['REFERNET_RADIUS_METERS'] || 48280.3).to_f 

  
  # Sets the base controller for OneclickRefernet Controllers
  OneclickRefernet.base_controller = Api::ApiController
  
  # Make refernet services feedbackable
  OneclickRefernet::Service.send(:include, Feedbackable)
  
  # Add some refernet-specific dashboard reports (check first if request log table exists)
  if ActiveRecord::Base.connection.table_exists? 'request_logs'
    DashboardReport.prebuilt_reports.merge!({
      popular_refernet_categories: [
        :popular_requests,
        requests: RequestLog.where(controller: "OneclickRefernet::SubCategoriesController")
                            .where(action: "index")
                            .where(created_at: DateTime.this_week),
        grouping_param: "category",
        title: "Popular 211 Category Requests this Week"
      ]
    })
  end
  
end
