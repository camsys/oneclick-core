
# Only run this code if OneclickRefernet module is included
if ENV["ONECLICK_REFERNET"]  
  # Set the refernet API token
  OneclickRefernet.api_token = 'KIXUUKWX'
  
  # Make refernet services feedbackable
  OneclickRefernet::Service.send(:include, Feedbackable)
end
