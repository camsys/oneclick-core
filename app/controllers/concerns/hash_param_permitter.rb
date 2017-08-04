# Service object for permitting complex hash params for serialized columns
class HashParamPermitter
  
  attr_accessor :hash_column, :case_column, :structure

  # Pass the params object when initializing
  def initialize(params)
    @params = params
    
    # Set instance variables based on the class instance variables
    @hash_column = self.class.hash_column
    @case_column = self.class.case_column
    @structure = self.class.structure
  end
  
  # Class Instance Variable Getters
  def self.hash_column; @hash_column end
  def self.case_column; @case_column end
  def self.structure; @structure end
  
  # Config Method defines appropriate instance methods, 
  # which may be overwritten as needed
  def self.define_hash_structure(params={})
    @hash_column = params[:hash_column]
    @case_column = params[:case_column]
    @structure = params[:structure]
    
    # Defines top-level permit method
    define_method(:permit) do
      # Return an empty array if the case column key is missing, or if it's an unknown key
      return [] unless  @params.has_key?(self.case_column) ||
                        self.structure.keys.include?(@params[self.case_column])

      # Otherwise, return an array with the hash column as key and list of permitted sub-params as value
      [self.hash_column => self.send("permit_#{@params[self.case_column]}")]
    end
    
    # Define a permit sub-method for each key in the structure
    # These methods may be overwritten by the inheriting class
    @structure.each do |key, value|
      define_method("permit_#{key}") do
        return value
      end
    end
  end

end
