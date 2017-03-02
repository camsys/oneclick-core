require 'rails_helper'

RSpec.describe User, type: :model do
  it { should have_many :trips }
  it { should have_and_belong_to_many :accommodations }
  it { should respond_to :roles }
  it { should have_many(:user_eligibilities) }
  it { should have_many(:eligibilities).through(:user_eligibilities) }
end
