require 'rails_helper'

RSpec.describe Api::V2::StompingGroundSerializer, type: :serializer do
  
  it_behaves_like "google_place_serializer" do
    let(:google_place) { create(:stomping_ground) }
  end

end
