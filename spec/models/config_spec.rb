require 'rails_helper'

RSpec.describe Config, type: :model do
  it { should respond_to :key }
  it { should respond_to :value }
end
