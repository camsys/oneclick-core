module CSVSerializable
  
  # Serializes an individual model as a CSV row
  def to_csv(opts={})
    attributes = opts[:attributes] || self.class.attribute_names
    attributes.map { |attr| self.send(attr) }
  end
  
  # Include class methods
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
    def csv_serializable(opts={}, &block)
      @csv_attributes ||= {}
      puts "CSV SERIALIZABLE", @csv_attributes
      
      template_name = opts[:template] || :default
      @csv_attributes[template_name] = self.attribute_names
      
      # @@csv_attributes[template_name] = ["bloop"]
    end
    
    def csv_attributes
      @csv_attributes
    end

    # Generates a CSV file of records
    # May pass an optional block that accepts the record and returns a hash of
    # attributes and values. If no block is passed, default to_csv method is called
    def to_csv(opts={}, &block)
      if block_given?
        attributes = yield(self.new).keys
      else
        # Set a default block which simply calls to_csv on the record, using all attribute_names
        attributes = opts[:attributes] || self.attribute_names
        block = lambda{|record| record.to_csv(attributes: attributes) }
      end

      batches_of = opts[:batches_of] || 100
        
      CSV.generate(headers: true) do |csv|
        csv << attributes # Header row
        
        in_batches(of: batches_of) do |batch|
          batch.all.each do |record|
            csv << block.call(record)
            # csv << record.to_csv(attributes: attributes)
          end
        end
      end
    end
    
  end
  
end
