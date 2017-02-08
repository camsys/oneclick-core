require 'rails_helper'

RSpec.describe User, type: :model do
  it { should have_many :trips }
  it { should respond_to :roles }
end
