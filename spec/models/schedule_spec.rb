require 'rails_helper'

RSpec.describe Schedule, type: :model do
  it { should respond_to :service, :day, :start_time, :end_time }
  let(:schedule) { create(:schedule, day: 3, start_time: 28800, end_time: 72000) }
  let(:all_day_schedule) { create(:all_day_schedule, day: 0) }

  let(:day_time_same_day) { DateTime.new(2020,1,1,17) }
  let(:night_time_same_day) { DateTime.new(2020,1,2,3,30) }
  let(:day_time_diff_day) { DateTime.new(2020,1,2,17) }
  let(:night_time_diff_day) { DateTime.new(2020,1,3,3,30) }
  let(:midnight_same_day) { DateTime.new(2020,1,5,12).in_time_zone.midnight }
  let(:midnight_next_day) { DateTime.new(2020,1,6,12).in_time_zone.midnight }

  it 'can include a time that falls within its day and time range' do
    expect(schedule.include?(day_time_same_day)).to be true
    expect(schedule.include?(night_time_same_day)).to be false
    expect(schedule.include?(day_time_diff_day)).to be false
    expect(schedule.include?(night_time_diff_day)).to be false
  end

  it 'can handle midnight edge cases' do
    expect(all_day_schedule.include?(midnight_same_day)).to be true
    expect(all_day_schedule.include?(midnight_next_day)).to be true
  end


end
