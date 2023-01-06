require 'rails_helper'

RSpec.describe Admin::FeedbacksController, type: :controller do

  let(:superuser) { create(:superuser) }
  let(:transportation_agency) { create :transportation_agency, :with_services }
  let(:transportation_staff) { create :transportation_staff, staff_agency: transportation_agency }
  let(:oversight_staff) { create :oversight_staff }
  let(:traveler) { create :user }
  let(:service_1) { transportation_agency.services.first }
  let(:service_2) { transportation_agency.services.last }

  let!(:acknowledged_feedback_1) { create :feedback, :acknowledged }
  let!(:acknowledged_feedback_2) { create :service_feedback, :acknowledged, rating: 2, feedbackable: service_1 }
  let!(:pending_feedback_1) { create :service_feedback, :pending, feedbackable: service_2 }
  let!(:pending_feedback_2) { create :service_feedback, :pending, review: nil, feedbackable: service_1 }
  let!(:pending_feedback_3) { create :feedback, :pending, rating: nil }
  
  
  # Superuser
  context "while signed in as a superuser" do
    
    before(:each) { sign_in superuser }
    
    it 'shows all pending feedback' do
      pending_feedback_count = Feedback.pending.count
      get :index
      expect(assigns(:feedbacks).count).to eq(pending_feedback_count)
    end
    
    it 'shows all acknowledged feedback' do
      acknowledged_feedback_count = Feedback.acknowledged.count
      get :acknowledged
      expect(assigns(:feedbacks).count).to eq(acknowledged_feedback_count)
    end
    
    it 'acknowledges a feedback, with a comment' do
      expect(pending_feedback_1.acknowledged?).to be false
      
      patch :update, params: {
        id: pending_feedback_1.id,
        feedback: {
          acknowledged: true,
          acknowledgement_comment_attributes: {
            comment: "I acknowledge this feedback"
          }
        }
      }
      
      expect(assigns(:feedback).id).to eq(pending_feedback_1.id)
      expect(assigns(:feedback).acknowledged?).to be true
    end
    
  end
  
  
  # PARTNER STAFF
  context "while signed in as oversight staff" do
    
    before(:each) { sign_in oversight_staff }
    
    it 'shows all pending feedback' do      
      pending_feedback_count = Feedback.pending.count
      get :index
      expect(assigns(:feedbacks).count).to eq(pending_feedback_count)
    end
    
    it 'shows all acknowledged feedback' do
      acknowledged_feedback_count = Feedback.acknowledged.count
      get :acknowledged
      expect(assigns(:feedbacks).count).to eq(acknowledged_feedback_count)
    end
    
    it 'acknowledges a feedback, with a comment' do
      expect(pending_feedback_1.acknowledged?).to be false
      
      patch :update, params: {
        id: pending_feedback_1.id,
        feedback: {
          acknowledged: true,
          acknowledgement_comment_attributes: {
            comment: "I acknowledge this feedback"
          }
        }
      }
      
      expect(assigns(:feedback).id).to eq(pending_feedback_1.id)
      expect(assigns(:feedback).acknowledged?).to be true
    end
  
  end
  
  
  # TRANSPORTATION STAFF
  context "while signed in as a transportation staff" do
    
    before(:each) { sign_in transportation_staff }
    
    it 'shows all pending feedback for staff agency' do
      pending_feedback_count = Feedback.about(transportation_staff.staff_agency.services).pending.count
      get :index
      expect(assigns(:feedbacks).count).to eq(pending_feedback_count)
    end
    
    it 'shows all acknowledged feedback for staff agency' do
      acknowledged_feedback_count = Feedback.about(transportation_staff.staff_agency.services).acknowledged.count
      get :acknowledged
      expect(assigns(:feedbacks).count).to eq(acknowledged_feedback_count)
    end
    
    it 'acknowledges a feedback, with a comment' do
      
      expect(pending_feedback_1.acknowledged?).to be false
      
      patch :update, params: {
        id: pending_feedback_1.id,
        feedback: {
          acknowledged: true,
          acknowledgement_comment_attributes: {
            comment: "I acknowledge this feedback"
          }
        }
      }
      
      expect(assigns(:feedback).id).to eq(pending_feedback_1.id)
      expect(assigns(:feedback).acknowledged?).to be true
    end
  
  end
  
  context "while signed in as a traveler" do
    
    before(:each) { sign_in traveler }
    
    it "prevents access to feedbacks page" do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
    
    it "prevents access to acknowledged feedbacks page" do
      get :acknowledged
      expect(response).to have_http_status(:unauthorized)
    end
    
  end
  
end
