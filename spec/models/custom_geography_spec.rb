require 'rails_helper'

RSpec.describe CustomGeography, type: :model do
  it { should respond_to :name, :geom }
end
