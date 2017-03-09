module GeoKitchen
  # Custom validator determines that recipe is a hash with arrays as key values
  class GeoRecipeValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      if value.is_a?(GeoRecipe)
        recipe = value.to_h
        if recipe.values.all?{|v| v.is_a?(Array)}
          if recipe.values.flatten.all?{|el| el.is_a?(Hash)}
          else
            record.errors.add(attribute, "Geography type array elements must all be hashes")
          end
        else
          record.errors.add(attribute, "Each geography type must have an array as value")
        end
      else
        record.errors.add(attribute, "Must be a GeoRecipe object")
      end
    end
  end


  class GeoRecipe
    attr_reader :hash

    def initialize(recipe_hash={})
      @hash = recipe_hash
    end

    def make
      puts "Making GeoRecipe into a geometry...", hash.ai
      geom = hash.map do |type, areas|
        geo_model = type.to_s.classify.constantize
        geoms = areas.map {|area| geo_model.find_by(area).geom }
        geoms.reduce { |combined_area, geom| combined_area.union(geom) }
      end.reduce { |combined_area, geom| combined_area.union(geom) }
      return geom
    end

    def to_h
      @hash
    end

    private

    # GeoRecipe#load and #dump allow this to respond to Rails serialize
    def self.load(recipe_hash)
      self.new(eval(recipe_hash || "{}"))
    end

    def self.dump(obj)

      unless obj.is_a?(self)
        raise ::ActiveRecord::SerializationTypeMismatch,
          "Attribute was supposed to be a #{self}, but was a #{obj.class}. -- #{obj.inspect}"
      end

      obj.to_h.to_s # Return a stringified hash
    end
  end

  class GeoIngredient
  end
end
