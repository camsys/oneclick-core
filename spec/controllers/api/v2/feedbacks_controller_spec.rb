require 'rails_helper'

RSpec.describe Api::V2::FeedbacksController, type: :controller do
  let(:traveler) { create :user }
  let(:request_headers) { {"X-USER-EMAIL" => traveler.email, "X-USER-TOKEN" => traveler.authentication_token} }
  let(:service) { create :service }
  
  it 'creates a feedback associated with logged in user and a service' do
    sign_in traveler
    feedback_params = attributes_for(:service_feedback).merge({
      user_id: traveler.id,
      feedbackable_type: 'Service',
      feedbackable_id: service.id
    })
    request.headers.merge!(request_headers) # Send user email and token headers
    
    traveler_feedbacks_count = traveler.feedbacks.count
    service_feedbacks_count = service.feedbacks.count
    
    post :create, params: {feedback: feedback_params}
    
    expect(response).to be_success
    
    expect(traveler.feedbacks.count).to eq(traveler_feedbacks_count + 1)
    expect(service.feedbacks.count).to eq(service_feedbacks_count + 1)
    
  end
  
  it 'creates a feedback for an anonymous user, with email and phone' do
    feedback_params = attributes_for(:service_feedback, :anonymous).merge({
      feedbackable_type: 'Service',
      feedbackable_id: service.id
    })
    
    service_feedbacks_count = service.feedbacks.count
    
    post :create, params: {feedback: feedback_params}
    
    expect(response).to be_success
    
    expect(service.feedbacks.count).to eq(service_feedbacks_count + 1)
    expect(Feedback.last.email).to eq(feedback_params[:email])
    expect(Feedback.last.phone).to eq(PhonyRails.normalize_number(feedback_params[:phone]))
  end
  
  it 'returns a list of user feedbacks' do
    rand(1..5).times do
      traveler.feedbacks << create(:feedback)
    end
    
    request.headers.merge!(request_headers)
    get :index
    
    expect(response).to be_success
    
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["data"]["feedbacks"].count).to eq(traveler.feedbacks.count)    
  end

  
end
