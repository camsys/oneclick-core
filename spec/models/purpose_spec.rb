require 'rails_helper'

RSpec.describe Purpose, type: :model do
  it { should respond_to :code }
  it { should respond_to :name } #This is a shorcut to pull the purpose name from translations
  it { should respond_to :snake_casify }
  it { should have_many :trips }
  it { should have_many :services }
end
