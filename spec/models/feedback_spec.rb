require 'rails_helper'

RSpec.describe Feedback, type: :model do
  
  it { should respond_to :comment, :rating }
  it { should belong_to(:user) }
  it { should belong_to(:feedbackable)}
  
end
