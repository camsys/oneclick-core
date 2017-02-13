namespace :db do 
  namespace :sample do
    desc "Setup Sample Landmarks"
    task landmarks: :environment do

      landmarks = [
                   {name: "Cambridge Systematics", street_number: "201", route: "Station Landing", 
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

    desc "Setup Sample Eligibilities"
    task eligibilities: :environment do
      eligs = [{code: "over_65"}, {code: "veteran"}, {code: "disability"}]

      eligs.each do |elig|
        Eligibility.where(code: elig[:code]).first_or_create!(elig)
      end
    end

    desc "Setup Sample Accommodations"
    task accommodations: :environment do
      accs = [{code: "wheelchair"}, {code: "assistance_to_door"}]

      accs.each do |acc|
        Accommodation.where(code: acc[:code]).first_or_create!(acc)
      end
    end

    #Load all sample data 
    task all: [:landmarks, :eligibilities, :accommodations]

  end
end 