require 'rails_helper'

RSpec.describe Place, type: :model do
  let(:trip) { create :trip }
  let(:place) { create :place }

  it ".trip method returns associated Trip object, regardless of whether origin or destination" do
    expect(trip.origin.trip).to eq(trip)
    expect(trip.destination.trip).to eq(trip)
    expect(place.trip).to be_nil
  end
end
