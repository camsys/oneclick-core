require 'rails_helper'

RSpec.describe Zipcode, type: :model do
  it { should respond_to :name, :geom }
end
