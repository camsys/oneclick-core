# Inheritable class for writing records to CSV files
class CSVWriter
  
  #################
  # CLASS METHODS #
  #################
  
  class << self
    attr_reader :headers, :associated_tables # Sets class variables on the inheriting class
  end
  
  ### CLASS CONFIGURATION METHODS ###
  # Configure inheriting classes by calling these methods in the class definition.
  # columns: This method is required. Must list all columns to include in the CSV.
  # associations: Optional. This will improve performance for columns that require table joins.
  # header_names: Optional. Overwrite column headers with custom text.
  ###
  
  # Config method for setting the columns to write to the file
  def self.columns(*cols)
    
    # For each column, check if a method is already defined. If not,
    # define a default one that calls that method on the passed record.
    cols.each do |col_name|
      unless method_defined?(col_name)
        define_method(col_name) do |record|
          record.send(col_name)
        end
      end
    end

    # Define default header names
    @headers ||= {} # initialize @headers if not done so already
    cols.each do |col_name|
      @headers[col_name] = col_name.to_s unless @headers[col_name]
    end
      
  end
  
  # Config method for identifying belongs_to tables to include in the query
  # Optional but highly recommended to improve performance--otherwise tables
  # are joined for each record in the collection
  def self.associations(*tables)
    @associated_tables = tables 
  end
  
  # Config method for overwriting default header names with custom text
  def self.header_names(dictionary={})
    @headers ||= {} # initialize @headers if not done so already
    dictionary.each { |k,v| @headers[k] = v }
  end
  
  
  ####################
  # INSTANCE METHODS #
  ####################
  
  attr_reader :records # Sets an instance variable on instances of the inheriting class
  
  # Initialize with a collection of the appropriate record type
  def initialize(records)
    @records = scope(records)
  end
  
  # Writes an entire CSV file
  def write_file(opts={})
    batches_of = opts[:batches_of] || 1000
    
    CSV.generate(headers: true) do |csv|
      csv << headers.values # Header row

      # Write rows for all records in the collection, in batches as defined.
      self.records.in_batches(of: batches_of) do |batch|
        batch.all.each do |record|
          csv << self.row_from(record)
        end
      end
    end
    
  end
  
  protected
  
  # Wrapper method for returning the list of column header names
  def headers
    self.class.headers
  end
  
  # Method scoping the records and joining to appropriate tables
  def scope(records)
    records.all.includes(self.class.associated_tables)
  end
    
  # Builds a CSV row for one record
  def row_from(record)
    headers.keys.map{ |h| self.send(h, record) }
  end
  
end
