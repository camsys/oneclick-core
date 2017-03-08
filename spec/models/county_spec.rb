require 'rails_helper'

RSpec.describe County, type: :model do
  it { should respond_to :name, :state, :geom }
end
