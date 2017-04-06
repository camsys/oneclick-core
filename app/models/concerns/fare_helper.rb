module FareHelper

  VALID_STRUCTURES = [nil, :flat, :mileage, :zone, :taxi_fare_finder]

  # Helper class for calculating trip fares
  class FareCalculator
    attr_reader :fare_structure, :fare_details, :trip

    # Initialize with a fare_structure, fare_details, trip, and options
    def initialize(fare_structure, fare_details, trip, options={})
      @fare_structure = fare_structure
      @fare_details = fare_details
      @trip = trip
      @http_request_bundler = options[:http_bundler] || HTTPRequestBundler.new
      @router = options[:router]
      @taxi_ambassador = options[:taxi_ambassador]
    end

    # Calculate the fare based on the passed trip and the fare_structure/details
    def calculate
      return no_fare if @fare_structure.nil?
      self.send("calculate_#{@fare_structure}")
    end

    # Calculates a flat fare
    def calculate_flat
      @fare_details[:base]
    end

    # Calculates a mileage-based fare
    def calculate_mileage
      @router = @router || default_router
      return (@fare_details[:base] +
        @fare_details[:mileage_rate] * @router.get_distance(@fare_details[:trip_type]))
    end

    # Calculates fare by making a call to TaxiFareFinder
    def calculate_taxi_fare_finder
      @taxi_ambassador = @taxi_ambassador || default_taxi_ambassador
      return @taxi_ambassador.fare(@fare_details[:taxi_fare_finder_city])
    end

    def calculate_zone
      0
    end

    private

    # Default result if no fare_structure is set
    def no_fare
      nil
    end

    # Builds a default OTPAmbassador if no router is provided
    def default_router
      OTPAmbassador.new(@trip, [@fare_details[:trip_type]], @http_request_bundler)
    end

    # Builds a default Taxi Fare Finder Ambassaor if no Taxi Ambassador is provided
    def default_taxi_ambassador
      TFFAmbassador.new(@trip, @http_request_bundler, cities: [@fare_details[:taxi_fare_finder_city]])
    end
  end

  # Validates fare_structure and fare_details
  class FareValidator
    attr_reader :fare_structure, :fare_details

    # Initialize with a fare_structure and fare_details
    def initialize(fare_structure, fare_details)
      @fare_structure = fare_structure
      @fare_details = fare_details
    end

    def valid?
      VALID_STRUCTURES.include?(@fare_structure.to_sym) &&
      self.send("valid_#{@fare_structure}?")
    end

    def valid_flat?
      @fare_details.has_key?(:base) && @fare_details[:base].is_a?(Numeric)
    end

    def valid_mileage?
      (@fare_details.has_key?(:base) && @fare_details[:base].is_a?(Numeric)) &&
      (@fare_details.has_key?(:mileage_rate) && @fare_details[:mileage_rate].is_a?(Numeric))
    end

    def valid_zone?
      true
    end

    def valid_taxi_fare_finder?
      true
    end

  end

end
