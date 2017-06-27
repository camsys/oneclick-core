class Role < ApplicationRecord
  
  ROLES = [ :admin, :staff ]
  
  belongs_to :resource,
             :polymorphic => true,
             :optional => true

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true
  validates :name,
            inclusion: { in: ROLES },
            allow_nil: false
            
  has_and_belongs_to_many :users, :join_table => :users_roles

  scopify
  

end
