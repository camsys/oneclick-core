require 'rails_helper'

RSpec.describe Admin::FeedbacksController, type: :controller do
  
  let!(:admin) { create :admin }
  let!(:non_admin) { create :user }
  let!(:acknowledged_feedback_1) { create :feedback, :acknowledged }
  let!(:acknowledged_feedback_2) { create :service_feedback, :acknowledged, rating: 2 }
  let!(:pending_feedback_1) { create :service_feedback, :pending }
  let!(:pending_feedback_2) { create :service_feedback, :pending, review: nil }
  let!(:pending_feedback_3) { create :feedback, :pending, rating: nil }
  

  before(:each) { sign_in admin }
  
  
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
