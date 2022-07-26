require 'rails_helper'

RSpec.describe Api::V2::TravelPatternsController, type: :controller do
  let!(:user) { create(:user) }
  let!(:user_agency) { create(:transportation_agency, name: "User Agency") }
  let(:user_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }

  let!(:purpose) { create(:purpose, agency: user_agency) } 
  let!(:weekly_pattern) { create(:travel_pattern, :with_weekly_pattern_schedule, agency: user_agency) }
  let!(:calendar_pattern) { create(:travel_pattern, :with_calendar_date_schedule, agency: user_agency) }
  let(:weekly_date) { (Date.current + 2.days).strftime('%Y-%m-%d') }
  let(:calendar_date) { (Date.current + 3.days).strftime('%Y-%m-%d') }

  before(:each) do
    create(:traveler_transit_agency, transportation_agency: user_agency, user: user)
    create(:travel_pattern_purpose, travel_pattern: weekly_pattern, purpose: purpose)
    create(:travel_pattern_purpose, travel_pattern: calendar_pattern, purpose: purpose)
    create(:travel_pattern, :with_weekly_pattern_schedule, agency: user_agency) # Extra Pattern
    create(:travel_pattern, :with_calendar_date_schedule, agency: user_agency) # Extra Pattern
    create(:travel_pattern) # Extra Pattern
  end

  context "When the Traveler is not logged in," do
    describe "GET index" do
      it "rejects unauthenticated requests" do
        get :index, params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  context "When the Traveler is logged in," do
    before(:each) do
      request.headers.merge!(user_headers)
    end

    describe "GET index" do
      it "responds successfully" do
        get :index, params: {}
        expect(response).to be_success
      end

      it "includes only travel patterns from the traveler's agency" do
        get :index, params: {}
        travel_patterns = JSON.parse(response.body)["data"]
        agency_ids = travel_patterns.map { |t| t["agency_id"] }

        expect(travel_patterns.length).to eq(TravelPattern.where(agency: user_agency).count)
        expect(agency_ids).to all(eq user_agency.id)
      end

      it "filters based on purpose" do
        get :index, params: {purpose: purpose[:name]}
        travel_patterns = JSON.parse(response.body)["data"]

        expect(travel_patterns.map { |t| t["id"] }).to eq([weekly_pattern, calendar_pattern].map(&:id))
      end

      it "selects travel patterns with weekly pattern schedules" do
        get :index, params: {date: weekly_date}
        weekly_travel_patterns = JSON.parse(response.body)["data"]

        expect(weekly_travel_patterns.map { |t| t["id"] }).to include(weekly_pattern.id)
        expect(weekly_travel_patterns.map { |t| t["id"] }).not_to include(calendar_pattern.id)
      end

      it "selects travel patterns with calendar date schedules" do
        get :index, params: {date: calendar_date}
        calendar_travel_patterns = JSON.parse(response.body)["data"]

        expect(calendar_travel_patterns.map { |t| t["id"] }).to include(calendar_pattern.id)
        expect(calendar_travel_patterns.map { |t| t["id"] }).not_to include(weekly_pattern.id)
      end

      it "filters based on both purpose_id and date at once" do
        get :index, params: {purpose: purpose[:name], date: weekly_date}
        travel_patterns = JSON.parse(response.body)["data"]

        expect(travel_patterns.map { |t| t["id"] }).to eq([weekly_pattern].map(&:id))
      end

      it "filters non-matching travel patterns based on time and duration" do
        time = 6.hours
        duration = 1.hours

        get :index, params: {start_time: time, end_time: time + duration}
        expect(response).to have_http_status(:not_found)
      end

      it "filters matching travel patterns based on time and duration" do
        time = 10.hours
        duration = 1.hours

        get :index, params: {start_time: time, end_time: time + duration}
        expect(response).to be_success
      end

      it "filters priotitize partially matching calendar date schedules over weekly schedules" do
        time = 10.hours
        duration = 4.hours

        new_schedule = create(:calendar_date_schedule, agency: user_agency)
        new_schedule.service_sub_schedules.first.update(calendar_date: Date.strptime(weekly_date, '%Y-%m-%d'), start_time: 9.hours, end_time: 11.hours)
        create(:travel_pattern_service_schedule, travel_pattern: weekly_pattern, service_schedule: new_schedule)

        get :index, params: {purpose: purpose[:name], date: weekly_date, start_time: time, end_time: time + duration}
        expect(response).to have_http_status(:not_found)
      end

      it "filters priotitize matching calendar date schedules over weekly schedules" do
        time = 10.hours
        duration = 4.hours

        new_schedule = create(:calendar_date_schedule, agency: user_agency)
        new_schedule.service_sub_schedules.first.update(calendar_date: weekly_date, start_time: 9.hours, end_time: 15.hours)
        create(:travel_pattern_service_schedule, travel_pattern: weekly_pattern, service_schedule: new_schedule)

        get :index, params: {purpose_id: purpose.id, date: weekly_date, start_time: time, end_time: time + duration}
        expect(response).to be_success
      end
    end
  end
end