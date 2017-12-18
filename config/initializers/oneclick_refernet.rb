
# Only run this code if OneclickRefernet module is included
if ENV["ONECLICK_REFERNET"]  
  # Set the refernet API token
  OneclickRefernet.api_token = 'KIXUUKWX'
  
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
                            .where(created_at: DateTime.this_week),
        grouping_param: "category",
        title: "Popular 211 Category Requests this Week"
      ]
    })
  end
  
end
