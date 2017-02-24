require 'rails_helper'

RSpec.describe Api::V1::TranslationsController, type: :controller do

  require 'rake'
  Rails.application.load_tasks
  Rake::Task['simple_translation_engine:update'].invoke

  it 'gets the save translation' do
    post :find, params: {"locale":"en","translations":["save"]}, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Check on a specific translation
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["save"]).to eq("Save")
  end

  it 'gets all the translations' do
    get :all, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Check on a specific translation
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["en"]["save"]).to eq("Save")
  end

  it 'gets all the English translations' do
    get :all, params: {"locale":"en"}, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Check on a specific translation
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["save"]).to eq("Save")
  end

end
