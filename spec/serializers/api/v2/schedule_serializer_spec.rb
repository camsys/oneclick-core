require 'rails_helper'

RSpec.describe Api::V2::ScheduleSerializer, type: :serializer do
  
  let(:schedule) { create(:schedule) }
  let(:serialization) { Api::V2::ScheduleSerializer.new(schedule).to_h }
  
  let(:attributes) { [ :day, :start_time, :end_time ] }
  
  it "faithfully serializes a schedule" do
    attributes.each do |attr|
      expect(serialization[attr]).to eq(schedule.send(attr))
    end
  end

end
