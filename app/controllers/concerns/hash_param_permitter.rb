# Service object for permitting complex hash params for serialized columns

# HOW TO USE:
# 1. Create a new class that inherits from HashParamPermitter
# 2. Call the define_hash_structure method in the class body,
#    passing the following options:
#    hash_column: Symbol name of the column that contains the hash
#    case_column: Symbol name of the column that determines which structure the hash should take
#    structure: A hash with a key for each possible case_column name, and
#      values which are arrays of each of the permitted params for that structure
# 3. If needed, overwrite any permit_col_name methods with custom methods for more complex structures
# 4. See FareParamPermitter or ServiceBookingParamPermitter for examples of how to implement

class HashParamPermitter
  
  # Pass the params object when initializing
  def initialize(params)
    @params = params
  end
  
  # Config Method defines appropriate instance methods, 
  # which may be overwritten as needed
  def self.define_hash_structure(params={})
    hash_column = params[:hash_column]
    case_column = params[:case_column]
    structure = params[:structure].with_indifferent_access # so strings and symbols both work

    # Defines top-level permit method
    define_method(:permit) do
      
      # Return an empty array if the case column key is missing, or if it's an unknown key
      return [] unless  @params.has_key?(case_column) &&
                        structure.keys.include?(@params[case_column])

      # Otherwise, return an array with the hash column as key and list of permitted sub-params as value
      [hash_column => self.send("permit_#{@params[case_column]}")]
    end
    
    # Define a permit sub-method for each key in the structure
    # These methods may be overwritten by the inheriting class
    structure.each do |key, value|
      define_method("permit_#{key}") do
        return value
      end
    end
  end

end
