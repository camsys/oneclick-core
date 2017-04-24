require 'rails_helper'

RSpec.describe UberExtension, type: :model do
  it { should respond_to :product_id, :itinerary }
end
