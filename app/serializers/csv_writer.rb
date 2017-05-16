# Inheritable class for writing records to CSV files
class CSVWriter
  
  attr_reader :records # Sets an instance variable on instances of the inheriting class

  ### CLASS METHODS ###
  
  class << self
    attr_reader :headers # Sets a class variable on the inheriting class
  end
  
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
    
    @headers = cols
  
  end
  
  
  ### INSTANCE METHODS ###
  
  # Initialize with a collection of the appropriate record type
  def initialize(records)
    @records = records
  end
  
  # Wrapper method for returning the list of column header names
  def headers
    self.class.headers
  end
    
  # Writes a CSV row for one record
  def write_row(record)
    headers.map{ |h| self.send(h, record) }
  end
  
  # Writes an entire CSV file
  def write_file(opts={})
    batches_of = opts[:batches_of] || 100
    
    CSV.generate(headers: true) do |csv|
      csv << self.class.headers # Header row
      
      self.records.in_batches(of: batches_of) do |batch|
        batch.all.each do |record|
          csv << self.write_row(record)
          # csv << record.to_csv(attributes: attributes)
        end
      end
    end
    
  end
  
end
