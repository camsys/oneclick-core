require 'rails_helper'

RSpec.describe Api::V2::FeedbackSerializer, type: :serializer do
  
  let(:feedback) { create(:service_feedback, :acknowledged) }
  let(:serialization) { Api::V2::FeedbackSerializer.new(feedback).to_h }
  
  let(:basic_attributes) {
    [
      :id, :rating, :review, :created_at, 
      :acknowledged, :email, :phone, :subject
    ]
  }
  
  it "faithfully serializes a feedback with acknowledgement data" do
    
    basic_attributes.each do |attr|
      expect(serialization[attr]).to eq(feedback.send(attr))
    end
    
    expect(serialization[:acknowledgement_comment]).to eq(feedback.comments.first.comment)
    expect(serialization[:acknowledged_at]).to eq(feedback.comments.first.updated_at)
    expect(serialization[:acknowledged_by]).to eq(feedback.comments.first.commenter.full_name)
    
  end

end
