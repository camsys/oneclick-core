require 'rails_helper'

RSpec.describe Trip, type: :model do
  it { should belong_to :user }
  it { should have_many :itineraries }
end
