require 'rails_helper'

RSpec.describe LyftExtension, type: :model do
  it { should respond_to :price_quote_id, :itinerary }
end