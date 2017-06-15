require 'rails_helper'

RSpec.describe Feedback, type: :model do
  
  # Test Context
  let(:service_feedback) { create(:service_feedback, email: nil, phone: nil) }
  let(:general_feedback) { create(:feedback) }
  let(:anonymous_feedback) { create(:feedback, :anonymous) }
  
  describe 'attributes and associations' do
  
    # Attributes
    it { should respond_to :comment, :rating, :acknowledged, :phone, :email }
    
    # Associations
    it { should belong_to(:user) }
    it { should belong_to(:feedbackable)}
    it { should have_one(:acknowledgement_comment) }
  
  end
  
  describe 'methods' do
  
    # Methods
    it { should respond_to :subject, :default_subject, :acknowledged? }
    
    it "should return a subject -- either the feedbackable or a default subject" do
      default_subject = Feedback::DEFAULT_SUBJECT
      
      expect(general_feedback.subject).to eq(default_subject)
      expect(service_feedback.subject).to eq(service_feedback.feedbackable.to_s)
    end
    
    it "contact_email should return email or user.email" do
      expect(service_feedback.contact_email).to eq(service_feedback.user.email)
      expect(anonymous_feedback.contact_email).to eq(anonymous_feedback.email)
    end
    
    it "contact_phone should return phone or user.phone" do
      expect(service_feedback.contact_phone).to eq(service_feedback.user.try(:phone))
      expect(anonymous_feedback.contact_phone).to eq(anonymous_feedback.phone)
    end
  
  end
  
end
