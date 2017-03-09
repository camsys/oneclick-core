require 'rails_helper'

RSpec.describe Accommodation, type: :model do
  it { should have_and_belong_to_many :users }
  it { should have_and_belong_to_many :services }
  it { should respond_to :code }
  it { should respond_to :snake_casify }
end
