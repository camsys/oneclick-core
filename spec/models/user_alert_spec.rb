require 'rails_helper'

RSpec.describe UserAlert, type: :model do
   it { should belong_to :user }
   it { should belong_to :alert }
   it { should respond_to :acknowledged }
end
