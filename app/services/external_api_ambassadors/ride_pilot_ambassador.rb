class RidePilotAmbassador
  
  attr_accessor :http_request_bundler, :url, :body, :headers
  
  def initialize(opts={})
    @url = opts[:url] || Config.ride_pilot_url
    @token = opts[:token] || Config.ride_pilot_token
    @headers = {
      "X-Ridepilot-Token" => @token,
      "Content-Type" => "application/json"
    }
    @http_request_bundler = opts[:http_request_bundler] || HTTPRequestBundler.new
    @body = {
      "provider_id"=>4,
    	"customer_id"=>7,
    	"customer_token"=>"c32c604455",
    	"trip_purpose"=>13,
    	"pickup_time"=>"2017-08-11T14:12:00.843-04:00",
    	"dropoff_time"=>"2017-08-11T16:12:00.843-04:00",
    	"attendants"=>0,
    	"guests"=>0,
    	"from_address"=>{
    		"address"=>{
    			"address_components" =>[
    				{
    			    	"long_name"=>"100 Cambridge Park Drive",
    			    	"short_name"=>"100 Cambridge Park Drive",
    			    	"types" =>[ "street_address"]
    			    },
    			    {
    			    	"long_name"=>"Cambridge",
    			    	"short_name"=>"Cambridge",
    			    	"types" =>[ "locality", "political"]
    			    },
    			    {
    			    	"long_name"=>"Massachusetts",
    			    	"short_name"=>"MA",
    			    	"types" =>["administrative_area_level_1", "political"]
    			    },
    			    {
    			    	"long_name"=>"02140",
    			    	"short_name"=>"02140",
    			    	"types" =>[ "postal_code"]
    			    }
    			],
    			"formatted_phone_number"=>"(617) 354-0167",
    			"geometry" =>{
    				"location" =>{
    			    	"lat" =>42.394307,
    			    	"lng" =>-71.144707
    				}
    			},
    			"name" =>"Cambridge Systematics"
    		}
    	},
    	"to_address"=>{
    		"address"=>{
    			"address_components" =>[
    				{
    			    	"long_name"=>"100 Cambridge Park Drive",
    			    	"short_name"=>"100 Cambridge Park Drive",
    			    	"types" =>[ "street_address"]
    			    },
    			    {
    			    	"long_name"=>"Cambridge",
    			    	"short_name"=>"Cambridge",
    			    	"types" =>[ "locality", "political"]
    			    },
    			    {
    			    	"long_name"=>"Massachusetts",
    			    	"short_name"=>"MA",
    			    	"types" =>["administrative_area_level_1", "political"]
    			    },
    			    {
    			    	"long_name"=>"02140",
    			    	"short_name"=>"02140",
    			    	"types" =>[ "postal_code"]
    			    }
    			],
    			"formatted_phone_number"=>"(617) 354-0167",
    			"geometry" =>{
    				"location" =>{
    			    	"lat" =>42.394307,
    			    	"lng" =>-71.144707
    				}
    			},
    			"name" =>"Cambridge Systematics"
    		}
    	}
    }.to_json
  end
  
  def book()
    EM.run do
      http = EM::HttpRequest.new(@url + "/create_trip").post(head: @headers, body: @body)
      http.errback { 
        puts http.response_header.status, http.response; EM.stop 
      }
      http.callback {
        puts http.response_header.status, http.response; EM.stop
      }
    end
  end
  
end
