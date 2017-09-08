require 'rails_helper'

RSpec.describe Alert, type: :model do
  it { should respond_to :en_subject }
  it { should respond_to :en_message }
end
