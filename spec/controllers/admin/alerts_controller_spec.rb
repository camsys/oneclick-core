require 'rails_helper'

RSpec.describe Admin::AlertsController, type: :controller do
  
  let(:admin) { create(:admin) }

  let!(:alert) { create(:alert) }
  let!(:expired_alert) { create(:expired_alert) }

  let(:everyone_params) {{
  	alert: { 
      translations: {
        en_subject: "english subject",
        en_message: "english message",
        es_subject: "",
        es_message: ""
      },
      expiration: "2017-09-15",
      audience: "everyone",
      audience_details: {
         user_emails: ""
      }
    }
  }}

  let(:specific_users_params) {{
  	alert: { 
      translations: {
        en_subject: "english subject 1",
        en_message: "english message",
        es_subject: "",
        es_message: ""
      },
      expiration: "2017-09-15",
      audience: "specific_users",
      audience_details: {
         user_emails: "#{admin.email},bad@email.com"
      }
    }
  }}

  context "while signed in as an admin" do
  
	  before(:each) { sign_in admin }
	  
	  it 'gets a list of all active alerts' do    
	    get :index
	    expect(response).to be_success
	  end

	  it 'gets a list of all expired alerts' do    
	    get :expired
	    expect(response).to be_success
	  end

	  it 'creates and destroys an alert' do
      params = everyone_params
      count = Alert.count
      
      post :create, params: params, format: :js
      expect(Alert.count).to eq(count + 1)
      expect(Alert.last.en_subject).to eq('english subject')
    
      delete :destroy, params: {id: Alert.last.id}, format: :js
      expect(Alert.count).to eq(count)
     end

    it 'creates and destroys specifc users request' do
      params = specific_users_params
      count = Alert.count

      post :create, params: params, format: :js
      expect(Alert.count).to eq(count + 1)
      expect(Alert.last.en_subject).to eq('english subject 1')
      expect(Alert.last.audience).to eq('specific_users')
      expect(Alert.last.audience_details[:user_emails]).to eq(admin.email)
    
      delete :destroy, params: {id: Alert.last.id}, format: :js
      expect(Alert.count).to eq(count)
    end

    it 'creates, updates, and destroys an alert' do
      params = everyone_params
      update_params = specific_users_params
      count = Alert.count
      
      post :create, params: params, format: :js
      expect(Alert.count).to eq(count + 1)
      expect(Alert.last.en_subject).to eq('english subject')
      expect(Alert.last.audience).to eq('everyone')

      put :update, params: {id: Alert.last.id}.merge(update_params), format: :js
      expect(Alert.count).to eq(count + 1)
      expect(Alert.last.en_subject).to eq('english subject 1')
      expect(Alert.last.audience).to eq('specific_users')
      expect(Alert.last.audience_details[:user_emails]).to eq(admin.email)

      delete :destroy, params: {id: Alert.last.id}, format: :js
      expect(Alert.count).to eq(count)

     end
  end
end