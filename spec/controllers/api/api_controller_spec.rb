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
  let(:request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  let(:bad_request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => "abcdefghijklmnop"} }
  let(:guest_request_headers) { { "X-USER-EMAIL" => guest.email } }

  it 'authenticates user from token & sets @traveler' do
    expect(controller.traveler).to be_nil
    request.headers.merge!(request_headers) # Send user email and token headers
    controller.authenticate_user_from_token
    expect(controller.traveler.email).to eq(request.headers["X-User-Email"])
  end
  
  it 'recognizes guest user email and sets @traveler' do
    expect(controller.traveler).to be_nil
    request.headers.merge!(guest_request_headers)
    controller.ensure_traveler
    expect(controller.traveler.email).to eq(request.headers["X-User-Email"])
  end

  it 'does not set traveler if bad token is passed' do
    expect(controller.traveler).to be_nil
    request.headers.merge!(bad_request_headers) # Send user email and token headers
    controller.authenticate_user_from_token
    expect(controller.traveler).to be_nil
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
