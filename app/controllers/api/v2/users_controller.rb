module Api
  module V2
    class UsersController < ApiController
      # include Devise::Controllers::SignInOut
      
      before_action :require_authentication, except: [:create, :new_session]

      # Get the user profile 
      def show
        render(success_response(
                @traveler, 
                serializer: UserSerializer))
      end

      # Update's the user's profile
      def update

        Rails.logger.info params.ai 

        if @traveler.update_profile(params)
          render(success_response(@traveler, serializer: UserSerializer))
        else
          render(fail_response(status: 500, message: "Unable to update."))
        end
      end
      
      # Sign up a new user
      # POST /sign_up
      # POST /users
      def create
        @user = User.new(user_params)
        
        if @user.save
          @user.ensure_authentication_token
          render(success_response(message: "User Signed Up Successfully", session: session_hash(@user)))
        else
          render(fail_response(errors: @user.errors.to_h))
        end
      end
      
      # Signs in an existing user, returning auth token
      # POST /sign_in
      def new_session
        @user = User.find_by(email: user_params[:email])
        
        if @user.present?
          if @user.valid_password?(user_params[:password])
            @user.ensure_authentication_token
            render(success_response(
                message: "User Signed In Successfully", 
                session: session_hash(@user)
              )) and return
          else
            @errors[:password] = "Incorrect password for #{@user.email}."
            @errors = @errors.merge(@user.errors.to_h)
          end
        else
          @errors[:email] = "Could not find user with email #{user_params[:email]}"
        end
        render(fail_response(errors: @errors))
      end
      
      # Signs out a user based on email and auth token headers
      # DELETE /sign_out
      def end_session
        
        if @traveler && @traveler.reset_authentication_token
          render(success_response(message: "User #{@traveler.email} successfully signed out."))
        else
          render(fail_response)
        end
        
      end
      
      private
      
      # Returns the signed in user's email and authentication token
      def session_hash(user)
        {
          email: user.email,
          authentication_token: user.authentication_token
        }
      end
      
      def user_params
        params.require(:user).permit(
          :email,
          :password,
          :password_confirmation,
          :first_name,
          :last_name          
        )
      end

    end
  end
end
