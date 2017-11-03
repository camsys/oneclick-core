class JsonLocaleLoader
  
  def initialize

  end
  
  # Parses a JSON file and returns a flatten hashed, with each key as the full path to its value
  def flat_hash_from_json_file(file_path)
    JSON.parse(File.read(file_path)).path_flatten
  end
  
  # This module is for extending the Hash class with a new method to flatten
  # a multi-level nested hash into a single-level hash, where each key is
  # the full path of the keys to get to that value.
  # e.g. { a: { b: 2 }, c: 3 }.path_flatten => { "a.b" => 2, "c" => 3 }
  module PathFlattenHash
    
    def path_flatten(prefix=nil)
      flattened_hash_array = self.flat_map do |k, v|
        new_prefix = [prefix, k].compact.join(".")
        if v.is_a?(Hash)
          next v.path_flatten(new_prefix)
        else
          next [ [new_prefix, v] ]
        end
      end
      
      prefix.present? ? flattened_hash_array : flattened_hash_array.to_h
    end
    
  end
  
  Hash.extend(PathFlattenHash)
  
end
