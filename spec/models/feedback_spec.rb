require 'rails_helper'

RSpec.describe Feedback, type: :model do
  
  # Test Context
  let(:service_feedback) { create(:service_feedback) }
  let(:general_feedback) { create(:feedback) }
  
  # Attributes
  it { should respond_to :comment, :rating, :acknowledged }
  
  # Associations
  it { should belong_to(:user) }
  it { should belong_to(:feedbackable)}
  it { should have_one(:acknowledgement_comment) }
  
  # Methods
  it { should respond_to :subject, :default_subject, :acknowledged? }
  
  it "should return a subject -- either the feedbackable or a default subject" do
    default_subject = Feedback::DEFAULT_SUBJECT
    
    expect(general_feedback.subject).to eq(default_subject)
    expect(service_feedback.subject).to eq(service_feedback.feedbackable.to_s)
  end
  
  
  
end
