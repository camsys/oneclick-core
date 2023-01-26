namespace :qa do
  namespace :sample do
    desc "Setup Sample Landmarks"
    task landmarks: :environment do

      landmarks = [
                   {name: "Cambridge Systematics", street_number: "101", route: "Station Landing",
                   city: "Medford", state: "MA", zip: "02155", lat: "42.401697", lng: "-71.081818"},

                   {name: "Fenway Park", street_number: "4", route: "Yawkey Way",
                   city: "Boston", state: "MA", zip: "02215", lat: "42.346636", lng: "-71.096013"},

                   {name: "Massachusetts General Hospital", street_number: "55", route: "Fruit Street",
                   city: "Boston", state: "MA", zip: "02214", lat: "42.363215", lng: "-71.068903"}
                 ]

      landmarks.each do |landmark|
        Landmark.where(name: landmark[:name]).first_or_create!(landmark)
      end
    end

    desc "Setup Sample Users"
    task users: :environment do
      
      users = [
                {first_name: "Test User 1", last_name: "Test", email: "test_user_1@camsys.com", 
                 password: "welcome1", password_confirmation: "welcome1"},
                {first_name: "Test User 2", last_name: "Test", email: "test_user_2@camsys.com", 
                 password: "welcome1", password_confirmation: "welcome1"}
              ]

      users.each do |user|
        User.where(email: user[:email]).first_or_create!(user)
      end
    end

    desc "Setup Sample Eligibilities"
    task eligibilities: :environment do
      eligs = [
        { code: 'medicaid' },
        { code: 'physically_disabled' },
        { code: 'ada' },
        { code: 'veteran' },
        { code: 'over_65' }
      ]

      eligs.each do |elig|
        Eligibility.where(code: elig[:code]).first_or_create!(elig)
        tk = TranslationKey.where(name: 'eligibility_' + elig[:code] + '_name').first_or_create 
        locale = Locale.find_by(name: "en")
        Translation.where(locale: locale, translation_key: tk, value: elig[:code].titleize).first_or_create
      end
    end

    desc "Setup Sample Accommodations"
    task accommodations: :environment do
      accs = [
        { code: 'folding_wheelchair' },
        { code: 'motorized_wheelchair' },
        { code: 'driver_assistance' },
        { code: 'curb_to_curb' },
        { code: 'door_to_door' }
      ]

      accs.each do |acc|
        Accommodation.where(code: acc[:code]).first_or_create!(acc)
        tk = TranslationKey.where(name: 'accommodation_' + acc[:code] + '_name').first_or_create 
        locale = Locale.find_by(name: "en")
        Translation.where(locale: locale, translation_key: tk, value: acc[:code].titleize).first_or_create
      end
    end


    desc "Setup Sample Purposes"
    task purposes: :environment do
      purps = [{name: "grocery"}, {name: "medical"}, {name: 'shopping'}]
      purps.each do |purp|
        Purpose.where(code: purp[:name]).first_or_create!(purp)
        tk = TranslationKey.where(name: 'purpose_' + purp[:name] + '_name').first_or_create 
        locale = Locale.find_by(name: "en")
        Translation.where(locale: locale, translation_key: tk, value: purp[:name].titleize).first_or_create
      end
    end

    desc "Setup Sample Services"
    task services: :environment do
      transit_service = Transit.find_or_create_by(name: "Sample Transit Service")
      transit_service.update_attributes(gtfs_agency_id: "1",
        phone: "555-555-5555", url: "http://www.mbta.com")

      paratransit_service = Paratransit.find_or_create_by(name: "Sample Paratransit Service")
      paratransit_service.accommodations << Accommodation.first << Accommodation.last
      paratransit_service.eligibilities << Eligibility.first << Eligibility.last
      paratransit_service.save
    end

    desc "Set Default Config Values"
    task config: :environment do
      Config.find_or_create_by(key: "open_trip_planner").update_attributes(value: "http://otp-ma.camsys-apps.com:8080/otp/routers/default")
    end

    desc "Test Samples"
    task test_geographies: :environment do
      puts "Uploading Sample Geographies..."
      counties_file = File.open("spec/files/test_sample_counties.zip")
      ShapefileUploader.new(counties_file,
        path: counties_file.path,
        content_type: "application/zip",
        geo_type: :county
      ).load
      cities_file = File.open("spec/files/test_sample_cities.zip")
      ShapefileUploader.new(cities_file,
        path: cities_file.path,
        content_type: "application/zip",
        geo_type: :city
      ).load
      zipcodes_file = File.open("spec/files/test_sample_zipcodes.zip")
      ShapefileUploader.new(zipcodes_file,
        path: zipcodes_file.path,
        content_type: "application/zip",
        geo_type: :zipcode,
        column_mappings: {name: "ZCTA5CE10"}
      ).load
    end

    desc "Feedback Samples"
    task feedback: :environment do
      Feedback.create(rating: 3, review: "OCC is meh", user: User.first)
      Feedback.create(rating: 5, review: "OCC is GREAT!!!", user: User.first)
    end

    desc "Stomping Grounds"
    task stomping_grounds: :environment do 
      u = User.find_or_create_by(email: 'test_user_1@camsys.com') do |user|
        user.password = 'welcome1'
        user.password_confirmation = 'welcome1'
        user.first_name = 'Test User 1'
        user.last_name = 'Test'
      end

      places = [
        {name: "Test Stomping Ground 1", street_number: "17", route: "Park Avenue",
        city: "Somerville", state: "MA", zip: "02144", lat: "42.398270", lng: "-71.122898"},
        {name: "Work", street_number: "101", route: "Station Landing",
        city: "Medford", state: "MA", zip: "02155", lat: "42.401697", lng: "-71.081818"}
      ]

      places.each do |place|
        StompingGround.where(name: place[:name], user: u).first_or_create!(place)
      end
    end

    desc "Sample Alerts"
    task alerts: :environment do
      expiration = Time.now + (60 * 60 * 24 * 365)

      u = User.find_or_create_by(email: 'test_user_1@camsys.com') do |user|
        user.password = 'welcome1'
        user.password_confirmation = 'welcome1'
        user.first_name = 'Test User 1'
        user.last_name = 'Test'
      end

      alerts = [
        {expiration: expiration, audience: "everyone", published: true, audience_details: {user_emails: ""}, 
          subject: "Test General Alert", message: "TGA Message"},
        {expiration: expiration, audience: "specific_users", published: true, 
          audience_details: {user_emails: "test_user_1@camsys.com"}, subject: "Test User 1 Alert", message: "TU1A Message"}
      ]
      alerts.each do |alert|
        new_alert = Alert.create(alert.except(:subject, :message))
        tk_subject = TranslationKey.where(name: 'alert_' + new_alert.id.to_s + '_subject').first_or_create
        tk_message = TranslationKey.where(name: 'alert_' + new_alert.id.to_s + '_message').first_or_create  
        locale = Locale.find_by(name: "en")
        Translation.where(locale: locale, translation_key: tk_subject, value: alert[:subject]).first_or_create
        Translation.where(locale: locale, translation_key: tk_message, value: alert[:message]).first_or_create
        locale = Locale.find_by(name: "es")
        Translation.where(locale: locale, translation_key: tk_subject, value: '[es] ' + alert[:subject] + ' [/es]').first_or_create
        Translation.where(locale: locale, translation_key: tk_message, value: '[es] ' + alert[:message] + '  [/es]').first_or_create

      end
    end

    #Load all sample data
    task all: [ :landmarks, :users, :eligibilities, :accommodations, :purposes,
                :services, :config, :feedback, :stomping_grounds, :alerts]

  end
end
