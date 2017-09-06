require 'rails_helper'

RSpec.shared_examples "commentable" do
  let(:factory) { described_class.to_s.underscore.to_sym }
  
  let(:commentable) { create(factory) }
  let(:comment_attrs) { attributes_for(:comment) }
  
  it { should respond_to :comment, :build_comment, :build_comments }
  it { should have_many(:comments).dependent(:destroy) }
  
  it "builds a comment by locale, or finds it if it exists" do
    expect(commentable.comment(:en)).to be nil
    
    commentable.build_comment(:en, comment_attrs).save
    expect(commentable.comment(:en).comment).to eq(comment_attrs[:comment])
    
    commentable.build_comment(:en, comment: "DIFFERENT COMMENT").save
    expect(commentable.comment(:en).comment).to eq("DIFFERENT COMMENT")
  end

  
end
