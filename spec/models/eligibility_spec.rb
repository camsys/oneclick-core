require 'rails_helper'

RSpec.describe Eligibility, type: :model do
  it { should respond_to :code }
  it { should respond_to :snake_casify }
  it { should have_many(:user_eligibilities) }
  it { should have_many(:users).through(:user_eligibilities) }
  it { should have_and_belong_to_many(:services) }
end
