# Makes a model "publishable" -- unpublished records should only show up in
# admin views, not in API call results
# For this to work, must add an "published" column to the including record table, e.g.:
  # add_column :agencies, :published, :boolean, default: false
  # add_index :agencies, :published
  
module Publishable
  
  # Set up default scope for including class
  def self.included(base)
    base.extend(ClassMethods)
    base.scope :published, -> { where(published: true) }
    base.scope :unpublished, -> { where.not(published: true) }
  end
  
  # Publishes the record
  def publish
    self.update_attributes(published: true)
  end
  
  # Unpublishes the record
  def unpublish
    self.update_attributes(published: false)
  end
  
  # Returns true if record is published
  def published?
    self.published
  end


  module ClassMethods
    
    # Publishes all records in a collection
    def publish_all
      all.update_all(published: true)
    end

    # Unpublishes all records in a collection
    def unpublish_all
      all.update_all(published: false)
    end

  end
  
end
