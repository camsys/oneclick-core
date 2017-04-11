module FareHelper
  include GeoKitchen

  VALID_STRUCTURES = [:flat, :mileage, :zone, :taxi_fare_finder]
  TRIP_TYPES = Trip::TRIP_TYPES

  # Helper class for calculating trip fares
  class FareCalculator
    attr_reader :fare_structure, :fare_details, :trip

    # Initialize with a fare_structure, fare_details, trip, and options
    def initialize(fare_structure, fare_details, trip, options={})
      @fare_structure = fare_structure
      @fare_details = fare_details
      @trip = trip
      @http_request_bundler = options[:http_request_bundler] || HTTPRequestBundler.new
      @router = options[:router]
      @taxi_ambassador = options[:taxi_ambassador]
      @origin_zone, @destination_zone = options[:origin_zone], options[:destination_zone]
    end

    # Calculate the fare based on the passed trip and the fare_structure/details
    def calculate
      return no_fare if @fare_structure.nil?
      self.send("calculate_#{@fare_structure}")
    end

    private

    # Calculates a flat fare
    def calculate_flat
      @fare_details[:base_fare]
    end

    # Calculates a mileage-based fare
    def calculate_mileage
      @router = @router || default_router
      return (@fare_details[:base_fare] +
        @fare_details[:mileage_rate] * @router.get_distance(@fare_details[:trip_type].to_sym))
    end

    # Calculates fare by making a call to TaxiFareFinder
    def calculate_taxi_fare_finder
      @taxi_ambassador = @taxi_ambassador || default_taxi_ambassador
      return @taxi_ambassador.fare(@fare_details[:taxi_fare_finder_city])
    end

    def calculate_zone
      fare_table = @fare_details[:fare_table]

      # Return no_fare if zone codes aren't accounted for in fare_table
      return no_fare unless fare_table.has_key?(@origin_zone)
      return no_fare unless fare_table[@origin_zone].has_key?(@destination_zone)

      # Look up fare in the fare_table by origin and destination zone codes
      fare_table[@origin_zone][@destination_zone]
    end

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
  class FareValidator < ActiveModel::Validator

    def validate(record)
      return if record.fare_structure.nil?
      if validate_fare_structure(record) && validate_fare_details(record)
        self.send("validate_#{record.fare_structure}", record)
      end
    end

    private

    def validate_fare_structure(record)
      if VALID_STRUCTURES.include?(record.fare_structure.underscore.to_sym)
        return true
      else
        record.errors.add(:fare_structure, "Must select a valid fare structure")
        return false
      end
    end

    def validate_fare_details(record)
      if record.fare_details.is_a?(Hash)
        return true
      else
        record.errors.add(:fare_details, "Fare details must be a hash")
        return false
      end
    end

    def validate_flat(record)
      # validate_fare_details_key(record, :base_fare, :numeric)
    end

    def validate_mileage(record)
      validate_fare_details_key(record, :base_fare, :numeric)
      validate_fare_details_key(record, :mileage_rate, :numeric)
      validate_fare_details_key(record, :trip_type, :symbol)
      unless TRIP_TYPES.include?(record.fare_details[:trip_type])
        record.errors.add(:fare_details, "Must have a valid trip_type")
      end
    end

    def validate_zone(record)
      has_keys =  validate_fare_details_key(record, :fare_zones, :hash) &&
                  validate_fare_details_key(record, :fare_table, :hash)
      if has_keys
        fare_zones = record.fare_details[:fare_zones]
        fare_table = record.fare_details[:fare_table]

        unless fare_table.keys == fare_zones.keys
          record.errors.add(:fare_details, "fare_table must have a row for each zone code")
        end

        unless fare_table.values.all?{|v| v.is_a?(Hash)}
          record.errors.add(:fare_details, "fare_table rows must all be hashes")
        end

        unless fare_table.values.all?{|v| v.keys == fare_zones.keys}
          record.errors.add(:fare_details, "fare_table rows must contain all zone codes")
        end

        # all fare_zone values must be valid GeoRecipes
        grv = GeoKitchen::GeoRecipeValidator.new(attributes: [:fare_details])
        fare_zones.values.each do |zone|
          grv.validate_each(record, :fare_details, zone)
        end

      end
    end

    def validate_taxi_fare_finder(record)
      validate_fare_details_key(record, :taxi_fare_finder_city, :string)
    end

    def validate_fare_details_key(record, key, class_name)
      valid = true
      unless record.fare_details.has_key?(key)
        record.errors.add(:fare_details, "Must have a #{key}")
        valid = false
      end
      class_ref = class_name.to_s.classify.constantize
      unless record.fare_details[key].is_a?(class_ref)
        record.errors.add(:fare_details, "#{key} must be a #{class_name}")
        valid = false
      end
      return valid
    end

  end

  # Permits proper Fare Params based on fare_structure
  class FareParamPermitter

    def initialize(params)
      @params = params
    end

    def permit
      return [] unless @params.has_key?(:fare_structure)
      [:fare_structure, fare_details: self.send("permit_#{@params[:fare_structure]}")]
    end

    def permit_flat
      [:base_fare]
    end

    def permit_mileage
      [:base_fare, :mileage_rate, :trip_type]
    end

    def permit_zone
      zones = @params[:fare_details][:fare_zones].keys.map{|k| k.to_sym}
      zone_recipes = zones.map {|z| { z => [:model, attributes: [:name, :state]]} }
      zone_grid = zones.map { |z| { z => zones } }
      [fare_zones: zone_recipes, fare_table: zone_grid]
    end

    def permit_taxi_fare_finder
      [:taxi_fare_finder_city]
    end

  end

  # Packages fare params as the proper serialized data type
  class FareParamPackager
    def initialize(params)
      @params = params
      @fare_structure = params[:fare_structure]
      @fare_details = params[:fare_details]
    end

    # Creates a fare_details parameter key based on the fare_structure
    def package
      self.send("package_#{@fare_structure}")
      return @params
    end

    private

    # Helper method, converts a param in place with passed block
    def convert_param(key, base_param=@fare_details, &block)
      base_param[key] = yield(base_param[key])
    end

    def package_flat
      convert_param(:base_fare) { |v| v.to_f }
    end

    def package_mileage
      convert_param(:base_fare) { |v| v.to_f }
      convert_param(:mileage_rate) { |v| v.to_f }
      convert_param(:trip_type) { |v| v.underscore.to_sym }
    end

    def package_taxi_fare_finder
      return true
    end

    def package_zone
      # Parse each fare_zone recipe into an array
      @fare_details[:fare_zones].each_key do |zone|
        convert_param(zone, @fare_details[:fare_zones]) {|v| JSON.parse(v) unless v.is_a?(Array) }
      end

      # Go through the table and convert fare values to floats
      @fare_details[:fare_table].each_key do |zone_r|
        @fare_details[:fare_table][zone_r].each_key do |zone_c|
          convert_param(zone_c, @fare_details[:fare_table][zone_r]) {|v| v.to_f }
        end
      end
    end
  end

end
