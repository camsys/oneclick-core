module Api
  module V3
    class SingleSignOnController < ApiController
      # before_action :require_authentication, only: []
      before_action :check_session_expiration, only: [:token]

      USER_POOL = 'esec-poc2'
      POOL_ID = 'us-west-1_0sKs3yy6v'
      REGION_ID = 'us-west-1'
			CLIENT_ID = '4fju6ojpi99e4jef1ue65nlu9l'
      CLIENT_SECRET = '3fe0iu432hpso9ik2edalo4lhg838n2j0mc4cukk4i10g8lj9m'
      COGNITO_DOMAIN = "https://#{USER_POOL}.auth.#{REGION_ID}.amazoncognito.com"
      AUTHORIZE_URL = COGNITO_DOMAIN + "/oauth2/authorize"
      TOKEN_URL = COGNITO_DOMAIN + "/oauth2/token"
      LOGOUT_URL = COGNITO_DOMAIN + "/logout"
			# LOGOUT_URL = 'https://oidcservicessyst.penndot.gov/siteminderagent/FMRSchedule/logout.fcc'

      def authorize
        # Store these untill AWS calls the callback endpoint
        reset_session
        session[:client_callback] = params.require(:clientCallback)
        session[:expires_at] = (Time.current + 10.minutes).httpdate

        # These params are required by AWS
        cognito_params = {
          response_type: "CODE",
          client_id: CLIENT_ID,
          redirect_uri: api_v3_sso_token_url
        }

        # Send the browser to AWS COGNITO
        redirect_to(AUTHORIZE_URL + "?" + cognito_params.to_query)
      end

      def token
        # Get the necessary variables
        # Clear the session to prevent accidental re-use of callback urls
        # Render an error unless everything is present
        params[:client_callback] = session[:client_callback]
        params[:expires_at] = session[:expires_at]
        reset_session

        code, client_callback, expires_at = params.require([:code, :client_callback, :expires_at])

        redirect_to(client_callback + "?" + {status: 200, code: code}.to_query)
      end

      def login
        code = params.require(:code)

        # Call AWS Cognito to get the JWT for the user
        resp = retrieve_cognito_token(code)
        render(status: :unauthorized, json: {status: resp.code}) and return unless resp.success?

        jwt = JSON.parse(resp.body)["id_token"]
        id_token, id_signature = JWT.decode(jwt, nil, false, { :algorithm => 'RS256' })

        account = AuthenticatedAccount.find_or_create_by(subject_uuid: id_token["sub"]) do |new_account|
          new_account.email = id_token["email"]
          new_account.account_type = AuthenticatedAccount.get_type_from_userDN(id_token["custom:userDN"])
        end

        # This works but wasn't being used
        # id_token["identities"].each { |identity|
        #   account.account_identities.find_or_create_by(
        #     identity: identity["userId"],
        #     provider: identity["providerName"]
        #   )
        # }

        @user = account.user
        json_response = {
          jwt: jwt,
          account_type: account.account_type
        }

        if @user
          @user.ensure_authentication_token
          booking_profile = @user.booking_profiles
                                  .with_valid_service
                                  .with_ecolane_api
                                  .first
          last_trip = @user.trips.order('created_at').last

          render status: 200, json: json_response.merge({
            authentication_token: @user.authentication_token,
            email: @user.email,
            first_name: @user.first_name,
            last_name: @user.last_name,
            last_origin: last_trip&.origin&.google_place_hash,
            last_destination: last_trip&.destination&.google_place_hash,
            sharedRideId: booking_profile&.details&.fetch(:customer_id),
            county: booking_profile&.details&.fetch(:county)
          })
        else
          render status: 200, json: json_response
        end
      end

      def account_setup
        jwt = params.require("jwt")
        id_token, id_signature = JWT.decode(jwt, nil, false, { :algorithm => 'RS256' })
        subject_uuid = id_token["sub"]
        email = id_token["email"]
        account = AuthenticatedAccount.find_by!(subject_uuid: subject_uuid)

        render(status: :conflict, json: { error: "account is already registered" }) and return if account.user

        # Attempt to use the registration params to check for an existing User
        # customer_number = EcolaneAmbassador.new({county: params[:county]}).lookup_customer_number({last_name: params[:last_name], date_of_birth: params[:date_of_birth]})
        @user = nil
        confirmation_method = registration_params[:confirmationMethod]
        county = registration_params[:county]
        service_id = registration_params[:serviceId]
        shared_ride_id = registration_params[:sharedRideId]
        dob = registration_params[:dob]

        if confirmation_method == 'sharedRideId'
          ecolane_params = {
            county: county,
            service: Service.find(service_id),
            ecolane_id: shared_ride_id,
            dob: dob
          }.select{ |k,v| v.present? }

          ambassador = EcolaneAmbassador.new(ecolane_params)
          @user = ambassador.user
        end

        render(status: :not_found, json: { error: "user could not be found" }) and return unless @user
        render(status: :conflict, json: { error: "user is already registered to another login" }) and return if @user.authenticated_accounts.any?

        @user.ensure_authentication_token
        booking_profile = @user.booking_profiles
                                .with_valid_service
                                .with_ecolane_api
                                .first
        last_trip = @user.trips.order('created_at').last

        AuthenticatedAccount.transaction do
          account.update!(user: @user)
          @user.email = email
          @user.save!
          booking_profile.details[:dob] = dob if dob
          booking_profile.details[:county] = county if county
          booking_profile.details[:esec] = true
          booking_profile.save!
        end

        render status: 200, json: {
          id_token: jwt,
          account_type: account.account_type,
          authentication_token: @user.authentication_token,
          email: @user.email,
          first_name: @user.first_name,
          last_name: @user.last_name,
          last_origin: last_trip&.origin&.google_place_hash,
          last_destination: last_trip&.destination&.google_place_hash,
          sharedRideId: booking_profile&.details&.fetch(:customer_id),
          county: booking_profile&.details&.fetch(:county)
        }
      end

      def logout
        # These params are required by AWS
        cognito_params = {
          response_type: "CODE",
          client_id: CLIENT_ID
        }
        
        redirect_to(LOGOUT_URL + "?" + cognito_params.to_query)
      end

      # make post route
      def admin
        @jwt = params.require("jwt");
        id_token, id_signature = JWT.decode(@jwt, nil, false, { :algorithm => 'RS256' })

        account = AuthenticatedAccount.last #find_by!(subject_uuid: id_token["sub"])
        @user = account.user

        if @user
          sign_in(:user, @user)
          @user.ensure_authentication_token
          redirect_to admin_path
        else
          @user = User.new
          session[:jwt] = @jwt
          render
        end
      end

      def link
        # @jwt = params[:user][:jwt]
        # id_token, id_signature = JWT.decode(@jwt, nil, false, { :algorithm => 'RS256' })
        account = AuthenticatedAccount.last # find_by!(subject_uuid: id_token["sub"])
        @user = user.find_by(email: params[:user][:email])
        
        if @user.valid_password?(password)
          sign_in(:user, @user)
          @user.ensure_authentication_token
          AuthenticatedAccount.update(user: user)
          redirect_to admin_path
        else
          # error
        end
      end

      private

      # --- Params ---
      def registration_params
        params.require(:esec).permit(:confirmationMethod, :county, :serviceId, :dob, :sharedRideId, :phoneNumber)
      end

      # --- Before Actions ---

      def check_session_expiration
        current_time = Time.current
        expiration_time = Time.parse(session[:expires_at])

        if (current_time >= expiration_time)
          reset_session
          render status: :unauthorized, json: json_response(:error, message: "It's been too long since the authentication process began.")
        end
      end

      # --- Helpers ---

      def origin_uri
        origin = URI.parse(request.referrer)
        origin.path = "/"
        origin.query = nil
        origin.fragment = "/login"

        return origin
      end

      def retrieve_cognito_token(code)
        cognito_params = {
          client_id: CLIENT_ID,
          grant_type: "authorization_code",
          code: code,
          client_secret: CLIENT_SECRET,
          redirect_uri: api_v3_sso_token_url
        }

        uri = URI.parse(TOKEN_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        req = Net::HTTP::Post.new(uri.request_uri)
        req.set_form_data(cognito_params)
        resp = http.start {|http| http.request(req)}

        return resp
      end
    end
  end
end

        # [
        #   {
        #     "at_hash"=>"IEWelAmmX6pkbMw22u_bnw",
        #     "sub"=>"25e643fa-5905-4739-b3f2-99ff53d794b4",
        #     "cognito:groups"=>[
        #       "us-west-1_0sKs3yy6v_PD-FMRScheduling"
        #     ],
        #     "email_verified"=>false,
        #     "iss"=>"https://cognito-idp.us-west-1.amazonaws.com/us-west-1_0sKs3yy6v",
        #     "cognito:username"=>"pd-fmrscheduling_pdtstfmrssystusr01",
        #     "preferred_username"=>"pdtstfmrssystusr01",
        #     "nonce"=>"u3ZTBN5hA6td5yci2R1Iz8cfJKw_VtEZhb4eTl_UfWIR0tHzmHr7J7xYCtMKPTHfBB1X5X6aTmbca6VzFfRdmg7KVnqgkoCEu2Q_HqZO0UBUzqmsk5v_mpUBjhOKdM_sBvwxpQoaXa4LiiIZ0ShCC1h6DJXQ3GJ7R5warjpsk10",
        #     "origin_jti"=>"77a2a1b0-e0db-4084-b663-0ed8e6125b88",
        #     "aud"=>"4fju6ojpi99e4jef1ue65nlu9l",
        #     "identities"=> [
        #       {
        #         "userId"=>"pdtstfmrssystusr01",
        #           "providerName"=>"PD-FMRScheduling",
        #           "providerType"=>"SAML",
        #           "issuer"=>"PD-FMRScheduling",
        #           "primary"=>"true",
        #           "dateCreated"=>"1666106834831"
        #         }
        #     ],
        #     "token_use"=>"id",
        #     "auth_time"=>1683143017,
        #     "exp"=>1683143317, 
        #     "iat"=>1683143017, 
        #     "custom:userDN"=>"CN=pdtstfmrssystusr01,OU=USERS,OU=TEST,OU=PD,OU=CWOPA,DC=PA-STGLAB,DC=LCL", 
        #     "jti"=>"a9f4161e-51aa-4317-8642-8870f24adbd4", 
        #     "email"=>"pdtsteseci2@pa.gov"
        #   }, 
        #   {
        #     "kid"=>"NW8PjFL7/uya5zFiimBrrPH8vb2sPIjbSKRqu3JcD3A=", 
        #     "alg"=>"RS256"
        #   }
        # ]
