module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json
    end
  end
end
