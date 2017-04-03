require 'rails_helper'

RSpec.describe Comment, type: :model do
  it { should belong_to :commentable }
  it { should respond_to :comment, :locale }
end
