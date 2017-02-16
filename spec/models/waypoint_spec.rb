require 'rails_helper'

RSpec.describe Waypoint, type: :model do
  let(:trip) { create :trip }
  let(:waypoint) { create :waypoint }

  it ".trip method returns associated Trip object, regardless of whether origin or destination" do
    expect(trip.origin.trip).to eq(trip)
    expect(trip.destination.trip).to eq(trip)
    expect(waypoint.trip).to be_nil
  end
end
