module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      # POST sign_up
      def create
        @user = User.new(sign_up_params)
        # check for presence of password_confirmation before attempting to save user
        if params[:password_confirmation] && @user.save
          render status: 200, json: {
            message: "User #{@user.email} successfully registered.",
            email: @user.email,
            authentication_token: @user.authentication_token
          }
        else
          render status: 422, json: {
            message: "User #{@user.email} could not be created.",
            errors: @user.errors.messages
          }
        end

      end

      private

      def sign_up_params
        params.require(:registration).permit(:email, :password, :password_confirmation, :first_name, :last_name)
      end

    end
  end
end
