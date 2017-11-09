module Api
  module V2
    class UsersController < ApiController
      # include Devise::Controllers::SignInOut
      
      before_action :require_authentication, except: [:create, :new_session]

      # Get the user profile 
      def show
        render(success_response(@traveler))
      end

      # Update's the user's profile
      def update

        Rails.logger.info params.ai 

        # user.update_profile call filters out any unsafe params
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
      # Leverages devise lockable module: https://github.com/plataformatec/devise/blob/master/lib/devise/models/lockable.rb
      def new_session
        @user = User.find_by(email: user_params[:email])
        
        # Check if a user was found based on the passed email. If so, continue authentication.
        if @user.present?
          # checks if password is incorrect and user is locked, and unlocks if lock is expired
          if @user.valid_for_authentication? { @user.valid_password?(user_params[:password]) } 
            @user.ensure_authentication_token
          else
            # Otherwise, add some errors to the response depending on what went wrong./
            @errors[:last_attempt] = "You have one more attempt before account is locked for #{User.unlock_in / 60} minutes." if @user.on_last_attempt?
            @errors[:locked] = "User account is temporarily locked. Try again in #{@user.time_until_unlock} minutes." if @user.access_locked?
            @errors[:password] = "Incorrect password for #{@user.email}." unless @user.access_locked? || @user.valid_password?(user_params[:password])
            @errors = @errors.merge(@user.errors.to_h)            
          end
        else
          @errors[:email] = "Could not find user with email #{user_params[:email]}"
        end

        # Check if any errors were recorded. If not, send a success response.
        if @errors.empty?
          render(success_response(
              message: "User Signed In Successfully", 
              session: session_hash(@user)
            )) and return
        else # If there are any errors, send back a failure response.
          render(fail_response(errors: @errors))
        end
        
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
