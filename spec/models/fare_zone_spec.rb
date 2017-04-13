require 'rails_helper'

RSpec.describe FareZone, type: :model do
  it { should respond_to :code }
  it { should belong_to :service }
  it { should belong_to :region }
end
