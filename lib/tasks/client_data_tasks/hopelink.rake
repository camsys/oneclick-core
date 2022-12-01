namespace :hopelink do

    desc "All hopelink rake tasks"
    task all: :environment do
        Rake::Task["hopelink:config"].invoke
        Rake::Task["hopelink:services"].invoke
    end

    desc "Setup Hopelink Services"
    task services: :environment do
        [
            {type: "Transit", name: "City of Seattle", published: true},
            {type: "Transit", name: "Community Transit", published: true},
            {type: "Transit", name: "Everett Transit", published: true},
            {type: "Paratransit", name: "Homage Senior Services", published: true},
            {type: "Transit", name: "Island Transit", published: true},
            {type: "Transit", name: "Kingcounty Marine Divison", published: true},
            {type: "Transit", name: "Kitsap Transit", published: true},
            {type: "Transit", name: "Metro Transit", published: true},
            {type: "Transit", name: "Muckleshoot Tribal Transit", published: true},
            {type: "Transit", name: "Pierce County Ferries", published: true},
            {type: "Paratransit", name: "Pierce County Human Services", published: true},
            {type: "Transit", name: "Pierce Transit", published: true},
            {type: "Transit", name: "Puget Sound Educational Service District", published: true},
            {type: "Transit", name: "Seattle Children's Hospital", published: true},
            {type: "Transit", name: "SeattleCenterMonorail", published: true},
            {type: "Transit", name: "Skagit Transit", published: true},
            {type: "Transit", name: "Snoqualmie Valley Transportation", published: true},
            {type: "Transit", name: "Solid Ground", published: true},
            {type: "Transit", name: "Sound Generations", published: true},
            {type: "Transit", name: "Sound Transit", published: true},
            {type: "Transit", name: "Washington State Ferries", published: true},
            {type: "Transit", name: "Whatcom Transportation Authority", published: true},
        ].each do |svc|
        puts "Creating #{svc[:type]} Service: #{svc[:name]}"
        Service.find_or_create_by(name: svc[:name])
                .update_attributes(svc)
        end
    end

    desc "Setup OTP version config"
    task config: :environment do
        Config.find_or_create_by(key: "open_trip_planner_verion").update_attributes(value: "v2")
    end
end