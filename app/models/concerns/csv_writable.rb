# Module allowing a collection of records to be exported as a CSV file
module CSVWritable

  # Include class methods
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
    # Config method sets the CSVWriter class to use when writing to CSV
    def write_to_csv(opts={})
      @csv_writer = opts[:with]
    end
    
    # Writes the current scope to a csv file
    def to_csv(opts={})
      csv_writer = opts[:with] || @csv_writer

      if opts[:limit]
        csv_writer.new(all).write_file_with_limit(opts)
      else
        csv_writer.new(all).write_file(opts)
      end
    end
    
  end
  
end
