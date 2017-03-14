module GeoKitchen

  # GeoRecipe is basically a list of GeoIngredients, and can "make" itself into a unified geometry
  class GeoRecipe
    attr_reader :ingredients, :errors

    # Takes an array of GeoIngredients
    def initialize(ingredients=[])
      @ingredients = ingredients.select {|i| i.is_a?(GeoIngredient)}
      @errors = []
      invalid_count = ingredients.length - @ingredients.length
      @errors << "#{invalid_count} arguments were not GeoIngredients" if invalid_count > 0
    end

    # Combine all the ingredients' geometries into a single unified geom, cast as a multipolygon
    def make
      output_geom = @ingredients.map do |ingredient|
        geom = ingredient.to_geom
        if geom
          geom
        else
          @errors << "#{ingredient.to_s} could not be converted to a geometry."
          nil
        end
      end.compact.reduce {|combined_area, geom| combined_area.union(geom)}
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
    def self.load(ingredients_array)
      ingredients_array = eval(ingredients_array || "[]")
      self.new(ingredients_array.map {|i| GeoIngredient.load(i)})
    end

    def self.dump(obj)
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
      @attributes = attributes
    end

    def name
      @attributes[:name]
    end

    def other_attributes
      @attributes.except(:name)
    end

    # Find the db record this ingredient refers to
    def find_record
      @model.find_by(@attributes)
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
      "#{name}, #{other_attributes.values.join(', ')}"
    end

    # For pretty printing
    def ai
      to_h.ai
    end

    # Prints as a nice text string for display
    def humanize
      "#{name} (#{other_attributes.values.join(' ')}) [#{@model}]"
    end

    # Load method for serializing; called by GeoRecipe
    def self.load(hash)
      self.new(hash[:model], hash[:attributes])
    end

  end
end
