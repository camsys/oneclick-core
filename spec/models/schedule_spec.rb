require 'rails_helper'

RSpec.describe Schedule, type: :model do
  it { should respond_to :service, :day, :start_time, :end_time }
  let(:schedule) { create(:schedule, day: 3, start_time: 28800, end_time: 72000) }
  let(:day_time_same_day) { DateTime.new(2020,1,1,17) }
  let(:night_time_same_day) { DateTime.new(2020,1,2,3,30) }
  let(:day_time_diff_day) { DateTime.new(2020,1,2,17) }
  let(:night_time_diff_day) { DateTime.new(2020,1,3,3,30) }

  it 'can include a time that falls within its day and time range' do
    puts "TIME ZONE: ", Time.zone.to_s
    puts "day_time_same_day", day_time_same_day
    expect(schedule.include?(day_time_same_day)).to be true
    expect(schedule.include?(night_time_same_day)).to be false
    expect(schedule.include?(day_time_diff_day)).to be false
    expect(schedule.include?(night_time_diff_day)).to be false
  end

end
