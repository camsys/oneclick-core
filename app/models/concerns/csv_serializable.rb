module CSVSerializable
  
  # Include class methods
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
  
    # Generates a CSV file of records
    def to_csv(opts={})
      attributes = opts[:attributes] || self.attribute_names
      batches_of = opts[:batches_of] || 100
      
      CSV.generate(headers: true) do |csv|
        csv << attributes # Header row
        
        in_batches(of: batches_of) do |batch|
          batch.all.each do |record|
            csv << attributes.map { |attr| record.send(attr) }
          end
        end
      end
    end
    
  end
  
end
