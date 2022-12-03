namespace :hopelink do

    desc "All hopelink rake tasks"
    task all: :environment do
        Rake::Task["hopelink:config"].invoke
        Rake::Task["hopelink:services"].invoke
    end

    # following this google spreadsheet:
    # https://docs.google.com/spreadsheets/d/1QHBQeKAGFbzjJdkm0bzKImmqGA3r08KgLRS0qdiOsEM/edit#gid=1919296759
    desc "Setup Hopelink Services"
    task services: :environment do
        [
            {type: "Transit", name: "American Cancer Society", published: true},
            {type: "Transit", name: "Catholic Community Services of Western Washington", published: true},
            {type: "Transit", name: "Catholic Community Services of Western Washington Snohomish", published: true},
            {type: "Transit", name: "Catholic Community Services of Western Washington Pierce County", published: true},
            {
                type: "Transit",
                name: "City of Seattle",
                gtfs_agency_id: "23",
                url: "https://www.seattle.gov/transportation/getting-around/transit/streetcar",
                phone: "206-684-7623",
                fare_structure: :url,
                fare_details: {url: "https://www.seattle.gov/transportation/getting-around/transit/streetcar/fares-and-orca-card
                "},
                published: true},
            {
                type: "Transit",
                name: "Community Transit",
                gtfs_agency_id: "29",
                email: "riders@commtrans.org",
                url: "http://www.communitytransit.org/",
                phone: "(800) 562-1375",
                fare_structure: :url,
                fare_details: {url: "https://www.communitytransit.org/fares/fares-and-passes"},
                published: true},
            {type: "Transit", name: "Disabled American Veterans", published: true},
            {
                type: "Transit",
                name: "Dungeness Line",
                gtfs_agency_id: "Dungeness Line",
                url: "https://dungeness-line.com",
                phone: "1-360-417-0700",
                fare_structure: :url,
                fare_details: {url: "https://dungeness-line.com/book-tickets/"},
                published: true},
            {type: "Transit", name: "Eastside Friends of Seniors", published: true},
            {type: "Transit", name: "Enumclaw Senior Center", published: true},
            {
                type: "Transit",
                name: "Everett Transit",
                gtfs_agency_id: "97",
                url: "http://www.everetttransit.org/",
                published: true},
            {
                type: "Paratransit",
                name: "Homage Senior Services",
                gtfs_agency_id: "2316",
                url: "https://homage.org/",
                published: true,
                accommodations: Accommodation.all,
                eligibilities: Eligibility.all,
            },
            {type: "Transit", name: "Hopelink", published: true},
            {
                type: "Transit",
                name: "Island Transit",
                gtfs_agency_id: "2271",
                url: "https://www.islandtransit.org/",
                phone: "(360) 678-7771",
                published: true
            },
            {type: "Transit", name: "Kaiser Permanente", published: true},
            {type: "Transit", name: "Kingcounty Marine Divison", published: true},
            {type: "Transit", name: "King County Metro", published: true},
            {
                type: "Transit",
                name: "Kitsap Transit",
                gtfs_agency_id: "kt",
                url: "http://www.kitsaptransit.com",
                phone: "(800) 501-7433",
                fare_structure: :url,
                fare_details: {url: "http://www.kitsaptransit.com/fares/fares"},
                published: true},
            {type: "Transit", name: "Lincoln Hill Retirement Community", published: true},
            {
                type: "Transit",
                name: "Metro Transit",
                gtfs_agency_id: "1",
                url: "http://metro.kingcounty.gov",
                phone: "206-553-3000",
                fare_structure: :url,
                fare_details: {url: "http://metro.kingcounty.gov/tops/bus/fare/fare-info.html#fare_matrix"},
                published: true
            },
            {type: "Transit", name: "Monroe Senior Center", published: true},
            {
                type: "Transit",
                name: "Muckleshoot Tribal Transit",
                gtfs_agency_id: "4901",
                url: "https://tribaltransit.com/",
                published: true},
            {
                type: "Paratransit",
                name: "Northshore Senior Center",
                gtfs_agency_id: "4918",
                url: "https://www.northshoreseniorcenter.org/programs-services/#1603576406908-16db901a-8dba",
                published: true,
                accommodations: Accommodation.all,
                eligibilities: Eligibility.all,
            },
            {
                type: "Paratransit",
                name: "Paratransit Services",
                published: true,
                accommodations: Accommodation.all,
                eligibilities: Eligibility.all,
            },
            {
                type: "Transit",
                name: "Pierce County Ferries",
                gtfs_agency_id: "1777",
                url: "https://www.co.pierce.wa.us/2200/Ferry-Schedule",
                published: true},
            # both Transit and Paratransit so make both so shows up in both filters.
            # If searched by gtfs agency id/name, doesnt matter which is returned as data is the same
            {
                type: "Transit",
                name: "Pierce County Human Services",
                gtfs_agency_id: "2361",
                url: "https://www.piercecountywa.gov/1269/Transportation-Services",
                published: true
            },
            {
                type: "Paratransit",
                name: "Pierce County Human Services",
                gtfs_agency_id: "2361",
                url: "https://www.piercecountywa.gov/1269/Transportation-Services",
                published: true,
                accommodations: Accommodation.all,
                eligibilities: Eligibility.all,
            },
            {
                type: "Transit",
                name: "Pierce Transit",
                gtfs_agency_id: "3",
                url: "http://www.piercetransit.org",
                phone: "(253)581-8000",
                published: true
            },
            {
                type: "Paratransit",
                name: "Puget Sound Educational Service District",
                gtfs_agency_id: "2309",
                url: "https://www.psesd.org/programs-services/administrative-management-services/transportation",
                published: true,
                accommodations: Accommodation.all,
                eligibilities: Eligibility.all,
            },
            {type: "Transit", name: "Puget Sound Express", published: true},
            {type: "Transit", name: "Rainier Foothills Transportation", published: true},
            {type: "Transit", name: "Sauk-Suiattle Tribe", published: true},
            {
                type: "Transit",
                name: "Seattle Children's Hospital",
                gtfs_agency_id: "98",
                url: "https://www.luum.com/commute/content/shuttles",
                published: true},
            {
                type: "Transit",
                name: "SeattleCenterMonorail",
                gtfs_agency_id: "96",
                url: "http://www.seattlemonorail.com",
                phone: "2069052620",
                published: true
            },
            {type: "Transit", name: "Skagit Transit", published: true},
            # both Transit and Paratransit so make both so shows up in both filters.
            # If searched by gtfs agency id/name, doesnt matter which is returned as data is the same
            {
                type: "Transit",
                name: "Snoqualmie Valley Transportation",
                gtfs_agency_id: "1824",
                url: "http://www.svtbus.org/",
                phone: "425-888-7001",
                published: true
            },
            {
                type: "Paratransit",
                name: "Snoqualmie Valley Transportation",
                gtfs_agency_id: "1824",
                url: "http://www.svtbus.org/",
                phone: "425-888-7001",
                published: true,
                accommodations: Accommodation.all,
                eligibilities: Eligibility.all,
            },
            {
                type: "Transit",
                name: "Solid Ground",
                gtfs_agency_id: "4902",
                url: "https://www.solid-ground.org/",
                published: true},
            {
                type: "Paratransit",
                name: "Sound Generations", 
                gtfs_agency_id: "2291",
                url: "https://soundgenerations.org/our-programs/transportation/",
                published: true,
                accommodations: Accommodation.all,
                eligibilities: Eligibility.all,
            },
            {
                type: "Transit",
                name: "Sound Transit",
                gtfs_agency_id: "40",
                url: "http://www.soundtransit.org/",
                phone: "1-888-889-6368",
                fare_structure: :url,
                fare_details: {url: "http://www.soundtransit.org/Fares-and-Passes.xml"},
                published: true
            },
            {type: "Transit", name: "Stillaguamish Tribe", published: true},
            {type: "Transit", name: "TransPro - Around the Sound", published: true},
            {
                type: "Transit",
                name: "Tulalip Transit",
                gtfs_agency_id: "4899",
                url: "https://www.tulaliptribes-nsn.gov/Dept/TulalipTransit",
                phone: "360-716-4000",
                published: true},
            {type: "Transit", name: "United Way of Pierce County", published: true},
            {type: "Transit", name: "Victoria Clipper", published: true},
            {
                type: "Transit",
                name: "Washington State Ferries",
                gtfs_agency_id: "95",
                url: "https://www.wsdot.wa.gov/ferries/",
                phone: "1 (888) 808-7977",
                fare_structure: :url,
                fare_details: {url: "https://wave2go.wsdot.com/webstore/landingPage?cg=21&c=76"},
                published: true},
            {
                type: "Transit",
                name: "Whatcom Transportation Authority",
                gtfs_agency_id: "14",
                url: "http://www.ridewta.com",
                phone: "1-866-989-4287",
                fare_structure: :url,
                fare_details: {url: "http://www.ridewta.com/fares-passes/fares"},
                published: true},
        ].each do |svc|
        puts "Creating #{svc[:type]} Service: #{svc[:name]}"
        Service.find_or_create_by!(type: svc[:type], name: svc[:name], agency_id: TransportationAgency.first.id)
                .update_attributes!(svc)
        end
    end

    desc "Setup OTP version config"
    task config: :environment do
        Config.find_by(key: "open_trip_planner").update_attributes!(value: "https://hopelink-otp.ibi-transit.com/otp/routers/default")
        Config.find_or_create_by!(key: "open_trip_planner_version").update_attributes!(value: "v2")
    end
end