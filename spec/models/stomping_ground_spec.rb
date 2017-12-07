require 'rails_helper'

RSpec.describe StompingGround, type: :model do

  it_behaves_like "place"

  it { should respond_to :user }

end
