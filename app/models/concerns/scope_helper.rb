module ScopeHelper

  # Include class methods
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Returns an ActiveRecord collection consisting of just itself
  def self_query
    self.class.where(id: id)
  end

  ### CLASS METHODS ###

  module ClassMethods

    # Builds boolean helper methods for each of the passed scope names
    def build_instance_scopes(*scopes)
      scopes.each do |scope|
        define_method("#{scope}?") do |*args|
          self_query.send(scope, *args).count > 0
        end
      end
    end

  end

end
