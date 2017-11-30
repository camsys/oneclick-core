
# Only run this code if OneclickRefernet module is included
if ENV["ONECLICK_REFERNET"]  
  # Set the refernet API token
  OneclickRefernet.api_token = 'KIXUUKWX'
  
  # Make refernet services feedbackable
  OneclickRefernet::Service.send(:include, Feedbackable)
  
  # Add some refernet-specific dashboard reports
  DashboardReport.prebuilt_reports.merge!({
    popular_refernet_categories: [
      :popular_requests,
      requests: RequestLog.where(controller: "OneclickRefernet::SubCategoriesController"),
      grouping_param: "category"
    ]
  })
  
end
