require 'rails_helper'

RSpec.describe Trip, type: :model do
  it { should belong_to :user }
  it { should have_many(:itineraries).dependent(:destroy) }
  it { should belong_to(:origin).class_name('Place').dependent(:destroy) }
  it { should belong_to(:destination).class_name('Place').dependent(:destroy) }
end
