module GeoKitchen

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    # Dynamically define instance methods on including model
    def acts_as_geo_ingredient(opts={})
      model = opts[:model] || self.name
      attributes = opts[:attributes] || [:name]

      # Returns a GeoIngredient refering to this county
      define_method("to_geo") do
        GeoIngredient.new(model, attributes.map{|a| [a, self.send(a)]}.to_h)
      end
    end

  end

  # GeoRecipe is basically a list of GeoIngredients, and can "make" itself into a unified geometry
  class GeoRecipe
    attr_reader :ingredients, :errors

    # Takes an array of GeoIngredients
    def initialize(ingredients=[])
      @ingredients = ingredients.select {|i| i.is_a?(GeoIngredient)}
      @errors = []
      @factory = RGeo::ActiveRecord::SpatialFactoryStore.instance.default
      invalid_count = ingredients.length - @ingredients.length
      @errors << "#{invalid_count} arguments were not GeoIngredients" if invalid_count > 0
    end

    # Combine all the ingredients' geometries into a single unified geom, cast as a multipolygon
    def make
      output_geom = @ingredients.map do |ingredient|
        geom = ingredient.to_geom
        if geom
          if geom.is_a?(RGeo::Geos::CAPIPointImpl)
            # Convert point into polygon.
            geom = geom.buffer(0.001)
          end
          geom
        else
          @errors << "#{ingredient.to_s} could not be converted to a geometry."
          nil
        end
      end.compact.reduce(@factory.multi_polygon([])) {|combined_area, geom| combined_area.union(geom)}
      RGeo::Feature.cast(output_geom, RGeo::Feature::MultiPolygon)
    end

    # Map its consituent ingredients to hashes
    def to_a
      @ingredients.map {|i| i.to_h}
    end

    # First convert to array, then to a string
    def to_s
      to_a.to_s
    end

    # First convert to array, then to JSON
    def to_json
      to_a.to_json
    end

    # For pretty printing
    def ai
      to_a.ai
    end

    # Prints as a nice text string for display
    def humanize
      @ingredients.map{|i| i.humanize}.join(', ')
    end

    private

    # GeoRecipe#load and #dump allow this to respond to Rails serialize
    def self.load(ingredients_array_str)
      self.from_array(eval(ingredients_array_str || "[]"))
    end

    def self.from_array(ingredients_array)
      self.new(ingredients_array.map {|i| GeoIngredient.load(i)})
    end

    def self.from_json(recipe_json)
      self.from_array(JSON.parse(recipe_json))
    end

    def self.dump(obj)
      obj = self.from_json(obj) if obj.is_a?(String)
      unless obj.is_a?(self)
        raise ::ActiveRecord::SerializationTypeMismatch,
          "Attribute was supposed to be a #{self}, but was a #{obj.class}. -- #{obj.inspect}"
      end
      obj.to_s # Return a stringified array
    end
  end

  class GeoIngredient
    attr_accessor :model, :attributes

    # Takes the name of a Database table model, and a list of attributes to identify it uniquely
    def initialize(model_name, attributes={})
      @model = model_name.to_s.classify.constantize
      @attributes = attributes.symbolize_keys
    end

    def name
      @attributes[:name]
    end

    def other_attributes
      @attributes.except(:name).except(:buffer)
    end

    # Find the db record this ingredient refers to
    def find_record
      @model.find_by(name: name)
    end

    # Get the geometry of the record this ingredient refers to
    def to_geom
      record = find_record
      record ? record.geom : false
    end

    # Converts to hash of key attributes
    def to_h
      {
        model: @model.name,
        attributes: @attributes
      }
    end

    # Converts to hash and then to string
    def to_s
      "#{name}, #{other_attributes.values.join(', ')} (#{@model.to_s})"
    end

    # For pretty printing
    def ai
      to_h.ai
    end

    # Converts to hash and then to JSON
    def to_json
      to_h.to_json
    end

    # Prints as a nice text string for display
    def humanize
      "#{name} (#{other_attributes.values.join(' ')}) [#{@model}]"
    end

    # Load method for serializing; called by GeoRecipe
    def self.load(hash)
      hash.symbolize_keys!
      self.new(hash[:model], hash[:attributes])
    end

  end

  # Validates input arrays for GeoRecipe from_array method
  class GeoRecipeValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      unless value.is_a?(Array)
        record.errors.add(attribute, "GeoRecipe #{value} must be an array.")
      else
        value.each {|ingredient| validate_ingredient(record, attribute, ingredient)}
      end
    end

    def validate_ingredient(record, attribute, value)
      unless value.is_a?(Hash)
        record.errors.add(attribute, "GeoIngredient #{value} must be a hash.")
      else
        unless value.has_key?(:model)
          record.errors.add(attribute, "GeoIngredient #{value} must include a :model key.")
        end

        unless value.has_key?(:attributes)
          record.errors.add(attribute, "GeoIngredient #{value} must include an :attributes key.")
        else
          unless value[:attributes].is_a?(Hash)
            record.errors.add(attribute, "GeoIngredient #{value}'s attributes must be a hash.")
          end
        end
      end
    end
  end
end
