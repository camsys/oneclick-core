require 'rails_helper'

RSpec.describe Purpose, type: :model do
  it { should respond_to :code }
  it { should respond_to :snake_casify }
end
