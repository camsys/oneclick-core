FactoryBot.define do
  factory :itinerary do
    
    trip { create(:trip) }
    cost { 1.6 }
    walk_time { 1246 }
    transit_time { 3167 }
    walk_distance { 1353.416 }
    wait_time { 242 }
    start_time { "2017-03-08T06:47:55.000-05:00".to_datetime }
    end_time { "2017-03-08T08:01:30.000-05:00".to_datetime }

    factory :transit_itinerary do
      legs { [{"startTime"=>1488973675000, "endTime"=>1488974852000, "departureDelay"=>0, "arrivalDelay"=>0, "realTime"=>false, "distance"=>1527.789, "pathway"=>false, "mode"=>"WALK", "route"=>"", "agencyTimeZoneOffset"=>-18000000, "interlineWithPreviousLeg"=>false, "from"=>{"name"=>"Origin", "lon"=>-76.769172, "lat"=>39.963016, "departure"=>1488973675000, "orig"=>"", "vertexType"=>"NORMAL"}, "to"=>{"name"=>"W. Market St. At Oxford St. Ob", "stopId"=>"5:576", "lon"=>-76.771061, "lat"=>39.9525429999999, "arrival"=>1488974852000, "departure"=>1488974853000, "stopIndex"=>6, "stopSequence"=>453, "vertexType"=>"TRANSIT"}, "legGeometry"=>{"points"=>"yg|rFj~psMOr@bATRFJ^FRNh@Nh@Nh@Nh@Nh@J^Nf@Ld@Nh@L^Lb@Lf@Nf@Ld@Ld@Nd@Jb@Nf@Nh@l@jBb@_@n@i@nA_@j@Mb@O^YT_@Pu@Fy@zCSdDi@dEq@fDk@~AY|AW|AYbB]jCe@nCg@Db@", "length"=>46}, "rentedBike"=>false, "transitLeg"=>false, "duration"=>1177.0, "intermediateStops"=>[], "steps"=>[{"distance"=>23.843, "relativeDirection"=>"DEPART", "streetName"=>"White Street", "absoluteDirection"=>"WEST", "stayOn"=>false, "area"=>false, "bogusName"=>false, "lon"=>-76.76917373630928, "lat"=>39.96301273621954, "elevation"=>[]}, {"distance"=>481.275, "relativeDirection"=>"LEFT", "streetName"=>"service road", "absoluteDirection"=>"SOUTH", "stayOn"=>false, "area"=>false, "bogusName"=>true, "lon"=>-76.7694328, "lat"=>39.9630937, "elevation"=>[]}, {"distance"=>239.637, "relativeDirection"=>"LEFT", "streetName"=>"White Street", "absoluteDirection"=>"SOUTHEAST", "stayOn"=>false, "area"=>false, "bogusName"=>false, "lon"=>-76.77409820000001, "lat"=>39.9609092, "elevation"=>[]}, {"distance"=>767.973, "relativeDirection"=>"RIGHT", "streetName"=>"North Oxford Street", "absoluteDirection"=>"SOUTH", "stayOn"=>false, "area"=>false, "bogusName"=>false, "lon"=>-76.77256200000001, "lat"=>39.9592857, "elevation"=>[]}, {"distance"=>15.061, "relativeDirection"=>"RIGHT", "streetName"=>"West Market Street", "absoluteDirection"=>"WEST", "stayOn"=>false, "area"=>false, "bogusName"=>false, "lon"=>-76.7708686, "lat"=>39.9525066, "elevation"=>[]}]}, {"startTime"=>1488974853000, "endTime"=>1488978000000, "departureDelay"=>0, "arrivalDelay"=>0, "realTime"=>false, "distance"=>25708.838796161966, "pathway"=>false, "mode"=>"BUS", "route"=>"16", "agencyName"=>"rabbittransit", "agencyUrl"=>"http://www.rabbittransit.org", "agencyTimeZoneOffset"=>-18000000, "routeColor"=>"C71585", "routeType"=>3, "routeId"=>"5:27", "routeTextColor"=>"FFFFFF", "interlineWithPreviousLeg"=>false, "tripBlockId"=>"161", "headsign"=>"Hanover Spring Grove", "agencyId"=>"0", "tripId"=>"5:tE00-sl12-p1304-r68", "serviceDate"=>"20170308", "from"=>{"name"=>"W. Market St. At Oxford St. Ob", "stopId"=>"5:576", "lon"=>-76.771061, "lat"=>39.9525429999999, "arrival"=>1488974852000, "departure"=>1488974853000, "stopIndex"=>6, "stopSequence"=>453, "vertexType"=>"TRANSIT"}, "to"=>{"name"=>"E. Walnut St. At York St.", "stopId"=>"5:687", "lon"=>-76.981114, "lat"=>39.800212, "arrival"=>1488978000000, "departure"=>1488978000000, "stopIndex"=>19, "stopSequence"=>3600, "vertexType"=>"TRANSIT"}, "legGeometry"=>{"points"=>"{ezrF|iqsMr@|GbAvEjDpPlCdGrFzInFbGtEjF~DbIfK`UnGlN|JbOxD|HtEbLlIhSvL~[`HvR~BzJjKle@|Gn[nAfMb@fEm@fAqAHUKs@yCsB_A]AD|@OnAj@d@rCfAvA@hBKhDk@tBZlB~@`JtK~P~SrVr[pe@fk@xGzHlO`JjO`MlQvKzB|BzRf_@lC|EpDhEfBrAtKpDtCb@pEVzAJnGhBbGxCfLdGbEvBjOnJpAfCE^Hb@RXTJVHVUj@Fr@l@\\FdBn@hEv@xFfAlHdBlDv@xAAnKs@zGe@fN_ApGsDzAUtADpBt@zExEfFbGdApG~@zKpB~FlGz[p@rAjBrAxLxGfM`LpArAtHjV`Nxb@pLzPbg@dr@|YzTjGxJpEtOfAfDbI|MjHnLlFzR~FjSpOjg@~EvOhFxMvv@jo@`O`OlJpFxEfAxETt@NtBr@vOrKhHvEtBfBzTlWb@l@rChGlB`FdAbJnDva@jDjZjB`S\\jHEzCuB~L_EdVe@fCsAlIfAx@", "length"=>133}, "routeShortName"=>"16", "routeLongName"=>"York To Hanover", "rentedBike"=>false, "transitLeg"=>true, "duration"=>3147.0, "intermediateStops"=>[{"name"=>"W. Market St. At Gotwalt St. Ob", "stopId"=>"5:584", "lon"=>-76.773554, "lat"=>39.9519469999999, "arrival"=>1488974891000, "departure"=>1488974891000, "stopIndex"=>7, "stopSequence"=>491, "vertexType"=>"TRANSIT"}, {"name"=>"W. Market St. At Hoffman Ln. Ob", "stopId"=>"5:592", "lon"=>-76.7777119999999, "lat"=>39.950307, "arrival"=>1488974961000, "departure"=>1488974961000, "stopIndex"=>8, "stopSequence"=>561, "vertexType"=>"TRANSIT"}, {"name"=>"2801 W. Market St. Ob", "stopId"=>"5:604", "lon"=>-76.7807849999999, "lat"=>39.9479079999999, "arrival"=>1488975026000, "departure"=>1488975026000, "stopIndex"=>9, "stopSequence"=>626, "vertexType"=>"TRANSIT"}, {"name"=>"W. Market St. At Hull Dr. Ob", "stopId"=>"5:609", "lon"=>-76.783574, "lat"=>39.945884, "arrival"=>1488975084000, "departure"=>1488975084000, "stopIndex"=>10, "stopSequence"=>684, "vertexType"=>"TRANSIT"}, {"name"=>"Us Rt. 30 At So. Salem Church Rd.", "stopId"=>"5:757", "lon"=>-76.8221929999999, "lat"=>39.930425, "arrival"=>1488975780000, "departure"=>1488975780000, "stopIndex"=>11, "stopSequence"=>1380, "vertexType"=>"TRANSIT"}, {"name"=>"Main St. At Railroad St. Ob", "stopId"=>"5:758", "lon"=>-76.8654049999999, "lat"=>39.8731859999999, "arrival"=>1488976440000, "departure"=>1488976440000, "stopIndex"=>12, "stopSequence"=>2040, "vertexType"=>"TRANSIT"}, {"name"=>"Wilson Ave At York St", "stopId"=>"5:871", "lon"=>-76.9472449999999, "lat"=>39.8081749999999, "arrival"=>1488977160000, "departure"=>1488977160000, "stopIndex"=>13, "stopSequence"=>2760, "vertexType"=>"TRANSIT"}, {"name"=>"York St. At Alvin St. Ib", "stopId"=>"5:643", "lon"=>-76.957076, "lat"=>39.8008669999999, "arrival"=>1488977462000, "departure"=>1488977462000, "stopIndex"=>14, "stopSequence"=>3062, "vertexType"=>"TRANSIT"}, {"name"=>"York St. At Mumma Ave. Ib", "stopId"=>"5:645", "lon"=>-76.96266, "lat"=>39.800006, "arrival"=>1488977583000, "departure"=>1488977583000, "stopIndex"=>15, "stopSequence"=>3183, "vertexType"=>"TRANSIT"}, {"name"=>"York St. At Center St. Ib", "stopId"=>"5:648", "lon"=>-76.967042, "lat"=>39.7991359999999, "arrival"=>1488977679000, "departure"=>1488977679000, "stopIndex"=>16, "stopSequence"=>3279, "vertexType"=>"TRANSIT"}, {"name"=>"York St. At Pleasant St. Ib", "stopId"=>"5:655", "lon"=>-76.974725, "lat"=>39.7990399999999, "arrival"=>1488977847000, "departure"=>1488977847000, "stopIndex"=>17, "stopSequence"=>3447, "vertexType"=>"TRANSIT"}, {"name"=>"York St. At E. Middle St. Ob", "stopId"=>"5:668", "lon"=>-76.9784389999999, "lat"=>39.800018, "arrival"=>1488977930000, "departure"=>1488977930000, "stopIndex"=>18, "stopSequence"=>3530, "vertexType"=>"TRANSIT"}], "steps"=>[]}, {"startTime"=>1488978000000, "endTime"=>1488978020000, "departureDelay"=>0, "arrivalDelay"=>0, "realTime"=>false, "distance"=>105.44340399940528, "pathway"=>false, "mode"=>"BUS", "route"=>"20N", "agencyName"=>"rabbittransit", "agencyUrl"=>"http://www.rabbittransit.org", "agencyTimeZoneOffset"=>-18000000, "routeColor"=>"2E8B57", "routeType"=>3, "routeId"=>"5:53", "routeTextColor"=>"FFFFFF", "interlineWithPreviousLeg"=>true, "tripBlockId"=>"161", "headsign"=>"20n  N Hanover Via Kindig", "agencyId"=>"0", "tripId"=>"5:tB12-sl12-p116C-r68", "serviceDate"=>"20170308", "from"=>{"name"=>"E. Walnut St. At York St.", "stopId"=>"5:687", "lon"=>-76.981114, "lat"=>39.800212, "arrival"=>1488978000000, "departure"=>1488978000000, "stopIndex"=>0, "stopSequence"=>0, "vertexType"=>"TRANSIT"}, "to"=>{"name"=>"Walnut St At Railroad St Ob", "stopId"=>"5:683", "lon"=>-76.982009, "lat"=>39.799559, "arrival"=>1488978020000, "departure"=>1488978021000, "stopIndex"=>1, "stopSequence"=>20, "vertexType"=>"TRANSIT"}, "legGeometry"=>{"points"=>"an|qF|jztM|C|D", "length"=>2}, "routeShortName"=>"20N", "routeLongName"=>"North Hanover Via Kindig", "rentedBike"=>false, "transitLeg"=>true, "duration"=>20.0, "intermediateStops"=>[], "steps"=>[]}, {"startTime"=>1488978021000, "endTime"=>1488978090000, "departureDelay"=>0, "arrivalDelay"=>0, "realTime"=>false, "distance"=>85.598, "pathway"=>false, "mode"=>"WALK", "route"=>"", "agencyTimeZoneOffset"=>-18000000, "interlineWithPreviousLeg"=>false, "from"=>{"name"=>"Walnut St At Railroad St Ob", "stopId"=>"5:683", "lon"=>-76.982009, "lat"=>39.799559, "arrival"=>1488978020000, "departure"=>1488978021000, "stopIndex"=>1, "stopSequence"=>20, "vertexType"=>"TRANSIT"}, "to"=>{"name"=>"Destination", "lon"=>-76.98261, "lat"=>39.79988, "arrival"=>1488978090000, "orig"=>"", "vertexType"=>"NORMAL"}, "legGeometry"=>{"points"=>"yi|qFdpztMDHJR}AfB", "length"=>4}, "rentedBike"=>false, "transitLeg"=>false, "duration"=>69.0, "intermediateStops"=>[], "steps"=>[{"distance"=>16.602, "relativeDirection"=>"DEPART", "streetName"=>"East Walnut Street", "absoluteDirection"=>"SOUTHWEST", "stayOn"=>false, "area"=>false, "bogusName"=>false, "lon"=>-76.98194005547327, "lat"=>39.799497212987845, "elevation"=>[]}, {"distance"=>68.996, "relativeDirection"=>"RIGHT", "streetName"=>"Baltimore Street", "absoluteDirection"=>"NORTHWEST", "stayOn"=>false, "area"=>false, "bogusName"=>false, "lon"=>-76.9820918, "lat"=>39.799404, "elevation"=>[]}]}] }
      service { create(:transit_service) }
      trip_type { "transit" }
    end

    factory :paratransit_itinerary do
      trip_type { "paratransit" }
      service {create(:paratransit_service, :medical_only, :with_schedules, :with_descriptions)}
      transit_time { 2336 }
      
      factory :strict_and_accommodating_paratransit_itinerary do
        service {create(:paratransit_service, 
                        :medical_only,
                        :strict, 
                        :accommodating, 
                        :with_schedules, 
                        :with_descriptions)}
      end
      
      factory :ride_pilot_itinerary do
        service { create(:paratransit_service, :ride_pilot_bookable) }
        trip { create(:trip) }
        after(:create) do |itin|
          s = itin.service
          u = itin.trip.user
          u.booking_profiles << create(:ride_pilot_user_profile, user: u, service: s)
        end
        
        trait :booked do
          booking { create(:ride_pilot_booking, :booked)}
          
          after(:create) do |itin|
            itin.select
          end
        end
        
        trait :canceled do
          booking { create(:ride_pilot_booking, :canceled)}
        end
        
        trait :unbooked do
          booking { nil }
        end
        
        factory :booked_itinerary do
          booked
        end
        
      end

      factory :ecolane_itinerary do
        service { create(:paratransit_service, :ecolane_bookable) }
        trip { create(:trip) }
        after(:create) do |itin|
          s = itin.service
          u = itin.trip.user
          u.booking_profiles << create(:ride_pilot_user_profile, user: u, service: s)
        end
        
        trait :booked do
          booking { create(:ride_pilot_booking, :booked)}
          
          after(:create) do |itin|
            itin.select
          end
        end
        
        trait :canceled do
          booking { create(:ride_pilot_booking, :canceled)}
        end
        
        trait :unbooked do
          booking { nil }
        end
        
        factory :ecolane_booked_itinerary do
          booked
        end
        
      end
      
    end


  end
end
