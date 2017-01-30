require 'rails_helper'

RSpec.describe Trip, type: :model do
  it { should belong_to :user }
  it { should have_many :itineraries }
  it { should belong_to(:origin).class_name('Place') }
  it { should belong_to(:destination).class_name('Place') }
end
