require 'rails_helper'

RSpec.describe Api::V2::UserAlertSerializer, type: :serializer do
  
  let(:user_alert) { create(:user_alert) }
  
  # Make a serialization for each locale
  let(:serializations) do
    I18n.available_locales.map do |l|
      [l, Api::V2::UserAlertSerializer.new(user_alert, scope: {locale: l}).to_h]
    end.to_h
  end  
  
  it "faithfully serializes a user alert, by locale" do
    serializations.each do |loc, user_alert_hash|
      expect(user_alert_hash[:id]).to eq(user_alert.id)
      expect(user_alert_hash[:subject]).not_to be_nil
      expect(user_alert_hash[:subject]).to eq(user_alert.subject(loc))
      expect(user_alert_hash[:message]).not_to be_nil
      expect(user_alert_hash[:message]).to eq(user_alert.message(loc))
    end
  end

end
