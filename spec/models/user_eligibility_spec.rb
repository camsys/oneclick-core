require 'rails_helper'

RSpec.describe UserEligibility, type: :model do
  it { should belong_to :user }
  it { should belong_to :eligibility }
  it { should respond_to :value }
end
