module FareHelper

  VALID_STRUCTURES = [:flat, :mileage, :zone, :taxi_fare_finder]

  # Helper class for calculating trip fares
  class FareCalculator
    attr_reader :fare_structure, :fare_details, :trip

    # Initialize with a fare_structure, fare_details, trip, and options
    def initialize(fare_structure, fare_details, trip, options={})
      @fare_structure = fare_structure
      @fare_details = fare_details
      @trip = trip
      @router = options[:router] || nil
      @trip_type = options[:trip_type] || :paratransit
    end

    # Calculate the fare based on the passed trip and the fare_structure/details
    def calculate
      self.send("calculate_#{@fare_structure}")
    end

    # Calculates a flat fare
    def calculate_flat
      @fare_details[:base]
    end

    # Calculates a mileage-based fare
    def calculate_mileage
      @fare_details[:base] +
      @fare_details[:mileage_rate] * @router.get_distance(@trip_type)
    end

    def calculate_taxi_fare_finder
      0
    end

    def calculate_zone
      0
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
