class Role < ApplicationRecord
  
  ROLES = [ :admin, :staff ]
  
  belongs_to :resource,
             :polymorphic => true,
             :optional => true

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true
  validates :name,
            inclusion: { in: ROLES.map(&:to_s) },
            allow_nil: false
            
  has_and_belongs_to_many :users, :join_table => :users_roles

  scopify
  
  scope :accessible_by_user, -> (user) { accessible_by(Ability.new(user)) }

end
