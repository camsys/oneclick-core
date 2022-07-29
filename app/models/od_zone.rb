class OdZone < GeographyRecord
  include LeafletAmbassador

  belongs_to :agency
  belongs_to :region, class_name: 'Region', foreign_key: :region_id, dependent: :destroy
  accepts_nested_attributes_for :region

  make_attribute_mappable :geom

  #scope :ordered, -> {joins(service: :agency).order("agencies.name")}
  scope :for_superuser, -> {all}
  scope :for_oversight_user, -> {all}
  scope :for_transport_user, -> {all}
  #scope :for_oversight_user, -> (user) {where(service: user.current_agency.service_oversight_agency.pluck(:service_id))}
  #scope :for_transport_user, -> (user) {where(service: user.current_agency.services)}

  validates_presence_of :agency
  validates :name, presence: true, uniqueness: true

  attr_accessor :start_or_end_area
  attr_accessor :zone_recipe

  def self.for_user(user)
    if user.superuser?
      for_superuser
    elsif user.currently_oversight?
      for_oversight_user(user).ordered
    elsif user.currently_transportation?
      for_transport_user(user).order("name desc")
    else
      nil
    end
  end

end