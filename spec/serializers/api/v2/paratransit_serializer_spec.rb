require 'rails_helper'

RSpec.describe Api::V2::ParatransitSerializer, type: :serializer do
  
  # Create a paratransit service with associated accommodations, eligibilities, schedules, and purposes
  it_behaves_like "api_v2_service_serializer" do
    let(:service) { create(:paratransit_service, 
                           :accommodating, 
                           :strict, 
                           :with_schedules, 
                           :medical_only) }
  end

end
