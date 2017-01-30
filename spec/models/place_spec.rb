require 'rails_helper'

RSpec.describe Place, type: :model do
    it { should have_one :trip_as_origin }
    it { should have_one :trip_as_destination }
    it { should respond_to :trip}
end
