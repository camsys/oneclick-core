require 'rails_helper'

RSpec.describe Itinerary, type: :model do
  it { should belong_to :trip }
end
