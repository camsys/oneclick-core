require 'rails_helper'

RSpec.describe City, type: :model do
  it { should respond_to :name, :state, :geom }
end
