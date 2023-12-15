# Allows a record to be "archived" or soft-deleted--an "archived" boolean is
# flipped and the record no longer shows up in the default scope
# For this to work, must add an "archived" column to the including record table, e.g.:
  # add_column :services, :archived, :boolean, default: false
  # add_index :services, :archived
module Archivable

  # Set up default scope for including class
  def self.included(base)

    # Sets default scope and other class methods
    base.extend(ClassMethods)

    # scope for all archived records
    base.scope :archived, -> { unscoped.where(archived: true) }

    # scope to include archive records in a query
    base.scope :include_archived, -> { unscope(where: :archived) }
  end

  # Archives the record
  def archive
    update_column(:archived, true)
  end

  # Restores the record from the archive
  def restore
    update_column(:archived, false)
  end

  # Returns true if record is archived
  def archived?
    !!self.archived
  end


  module ClassMethods

    # Default scope excludes archived records
    def default_scope
      where.not(archived: true)
    end

    # Archives all records in a collection
    def archive_all
      all.update_all(archived: true)
    end

    # Restores all records in a collection
    def restore_all
      all.include_archived.update_all(archived: false)
    end

  end

end
