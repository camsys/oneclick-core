require 'rails_helper'

RSpec.describe Api::V2::ServicesController, type: :controller do
  
  before(:each) do
    
    # Create a random number of services of each type, and randomly decide whether
    # or not to publish them
    Service::SERVICE_TYPES.each do |type|
      rand(3..6).times { |_| create(:service, type: type, published: [true, false].sample) }
    end
  end
  
  it "returns all published services" do
    get :index
    
    expect(response).to be_success
    
    services = JSON.parse(response.body)["data"]["services"]
        
    expect(services.count).to eq(Service.published.count)
    
    # Expect each of the following attributes to be present in the JSON results
    [:id, :type, :name, :phone, :email, :url].each do |attr|
      expect(services.first[attr.to_s]).to be
    end
  end
  
  it "filters services by type" do
    Service::SERVICE_TYPES.each do |type|
      
      get :index, params: { type: type }
      services = JSON.parse(response.body)["data"]["services"]
      
      # Expect count of returned services to equal the count of all published
      # services of that type
      expect(services.count).to eq(Service.published.where(type: type).count)      
    end
  end

end
