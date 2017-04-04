require 'rails_helper'

RSpec.describe Purpose, type: :model do
  it { should respond_to :code }
  it { should respond_to :snake_casify }
  it { should have_many :trips }
  it { should have_and_belong_to_many :services }
end
