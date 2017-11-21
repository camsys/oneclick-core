require 'rails_helper'

RSpec.describe RequestLog, type: :model do
  it { should respond_to :controller, :action, :status_code, 
                         :params, :auth_email, :duration, :created_at }
end
