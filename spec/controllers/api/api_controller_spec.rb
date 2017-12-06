require 'rails_helper'

RSpec.describe Api::ApiController, type: :controller do
  # This line is necessary to get Devise scoped tests to work.
  before(:each) { @request.env["devise.mapping"] = Devise.mappings[:user] }
  before(:all) { # Create some locales
    create(:locale_en)
    create(:locale_es)
    create(:locale_fr)
  }
  let(:user) { create(:spanish_speaker) }
  let(:guest) { create(:guest) }
  
  let(:headers_reg_valid) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  let(:headers_reg_invalid) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => "FAKEAUTHTOKEN"} }
  let(:headers_reg_incomplete) { {"X-USER-EMAIL" => user.email } }
  
  let(:headers_guest) { { "X-USER-EMAIL" => guest.email } }
  let(:headers_guest_w_token) do
    guest.ensure_authentication_token
    guest.save
    { "X-USER-EMAIL" => guest.email, "X-USER-TOKEN" => guest.authentication_token }
  end
  
  let(:request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  let(:bad_request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => "abcdefghijklmnop"} }
  let(:guest_request_headers) { { "X-USER-EMAIL" => guest.email } }

  it 'has a test action' do
    get :test, format: :json
    expect(response).to be_success
  end
  
  context 'do not require authentication (default)' do
        
    it 'authenticates registered traveler if valid auth headers are passed' do
      request.headers.merge!(headers_reg_valid)
      get :test, format: :json
      expect(response).to be_success
      expect(controller.traveler).to eq(user)
    end
    
    it 'succeeds but does not authenticate registered traveler if invalid auth headers are passed' do
      request.headers.merge!(headers_reg_invalid)
      get :test, format: :json
      expect(response).to be_success
      expect(controller.traveler).to be_nil
    end
    
    it 'succeeds but does not authenticate registered traveler if email only is passed' do
      request.headers.merge!(headers_reg_incomplete)
      get :test, format: :json
      expect(response).to be_success
      expect(controller.traveler).to be_nil
    end
    
    it 'authenticates guest traveler if email only is passed' do
      request.headers.merge!(headers_guest)
      get :test, format: :json
      expect(response).to be_success
      expect(controller.traveler).to eq(guest)
    end
    
    it 'authenticates guest traveler if email and token are passed' do
      request.headers.merge!(headers_guest_w_token)
      get :test, format: :json
      expect(response).to be_success
      expect(controller.traveler).to eq(guest)
    end
    
    it 'succeeds but does not create a guest traveler if no auth headers are passed' do
      get :test, format: :json
      expect(response).to be_success
      expect(controller.traveler).to be_nil
    end
    
  end

  context 'require authentication' do
    
    it 'authenticates registered traveler if valid auth headers are passed' do
      request.headers.merge!(headers_reg_valid)
      get :test, format: :json, params: {before_action: :require_authentication}
      expect(response).to be_success
      expect(controller.traveler).to eq(user)
    end
    
    it 'throws 401 error if invalid auth headers are passed' do
      request.headers.merge!(headers_reg_invalid)
      get :test, format: :json, params: {before_action: :require_authentication}
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'throws 401 error if email only is passed' do
      request.headers.merge!(headers_reg_incomplete)
      get :test, format: :json, params: {before_action: :require_authentication}
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'throws 401 error if guest email only is passed' do
      request.headers.merge!(headers_guest)
      get :test, format: :json, params: {before_action: :require_authentication}
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'authenticates guest traveler if email and token are passed' do
      request.headers.merge!(headers_guest_w_token)
      get :test, format: :json, params: {before_action: :require_authentication}
      expect(response).to be_success
      expect(controller.traveler).to eq(guest)
    end
    
    it 'throws 401 error if no auth headers are passed' do
      get :test, format: :json, params: {before_action: :require_authentication}
      expect(response).to have_http_status(:unauthorized)
    end
      
  end
  
  context 'attempt authentication' do
    
    it 'authenticates registered traveler if valid auth headers are passed' do
      request.headers.merge!(headers_reg_valid)
      get :test, format: :json, params: {before_action: :attempt_authentication}
      expect(response).to be_success
      expect(controller.traveler).to eq(user)
    end
    
    it 'throws 401 error if invalid auth headers are passed' do
      request.headers.merge!(headers_reg_invalid)
      get :test, format: :json, params: {before_action: :attempt_authentication}
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'throws 401 error if email only is passed' do
      request.headers.merge!(headers_reg_incomplete)
      get :test, format: :json, params: {before_action: :attempt_authentication}
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'authenticates guest traveler if email only is passed' do
      request.headers.merge!(headers_guest)
      get :test, format: :json, params: {before_action: :attempt_authentication}
      expect(response).to be_success
      expect(controller.traveler).to eq(guest)
    end
    
    it 'authenticates guest traveler if email and token are passed' do
      request.headers.merge!(headers_guest_w_token)
      get :test, format: :json, params: {before_action: :attempt_authentication}
      expect(response).to be_success
      expect(controller.traveler).to eq(guest)
    end
    
    it 'creates a guest traveler if no auth headers are passed' do
      get :test, format: :json, params: {before_action: :attempt_authentication}
      expect(response).to be_success
      expect(controller.traveler).to be
      expect(controller.traveler.guest?).to be true
    end
    
  end
  
  context 'ensure traveler' do
    
    it 'authenticates registered traveler if valid auth headers are passed' do
      request.headers.merge!(headers_reg_valid)
      get :test, format: :json, params: {before_action: :ensure_traveler}
      expect(response).to be_success
      expect(controller.traveler).to eq(user)
    end
    
    it 'succeeds and creates a guest traveler if invalid auth headers are passed' do
      request.headers.merge!(headers_reg_invalid)
      get :test, format: :json, params: {before_action: :ensure_traveler}
      expect(response).to be_success
      expect(controller.traveler).to be
      expect(controller.traveler.guest?).to be true
    end
    
    it 'succeeds and creates a guest traveler if email only is passed' do
      request.headers.merge!(headers_reg_incomplete)
      get :test, format: :json, params: {before_action: :ensure_traveler}
      expect(response).to be_success
      expect(controller.traveler).to be
      expect(controller.traveler.guest?).to be true
    end
    
    it 'authenticates guest traveler if email only is passed' do
      request.headers.merge!(headers_guest)
      get :test, format: :json, params: {before_action: :ensure_traveler}
      expect(response).to be_success
      expect(controller.traveler).to eq(guest)
    end
    
    it 'authenticates guest traveler if email and token are passed' do
      request.headers.merge!(headers_guest_w_token)
      get :test, format: :json, params: {before_action: :ensure_traveler}
      expect(response).to be_success
      expect(controller.traveler).to eq(guest)
    end
    
    it 'creates a guest traveler if no auth headers are passed' do
      get :test, format: :json, params: {before_action: :ensure_traveler}
      expect(response).to be_success
      expect(controller.traveler).to be
      expect(controller.traveler.guest?).to be true
    end
    
  end

  it 'sets the locale based on params, traveler preference, or default' do
    # Should be en by default
    controller.set_locale
    expect(assigns(:locale)).to eq(I18n.default_locale.to_s)
    
    # With traveler signed in, locale should be traveler's preferred
    request.headers.merge!(request_headers)
    controller.authenticate_user_from_token
    controller.set_traveler
    controller.set_locale
    expect(assigns(:locale)).to eq(user.preferred_locale.name)
    
    # If locale param is set to a valid locale, expect that to overwrite @locale
    controller.params[:locale] = "fr"
    controller.set_locale
    expect(assigns(:locale)).to eq("fr")
    
    # If locale param is set to an unsupported locale, expect it to fall back to user's locale
    controller.params[:locale] = "xx"
    controller.set_locale
    expect(assigns(:locale)).to eq(user.preferred_locale.name)
  end
  
end
