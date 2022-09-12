class OdZone < GeographyRecord
  include GeoKitchen
  include LeafletAmbassador

  belongs_to :agency
  belongs_to :region, class_name: 'Region', foreign_key: :region_id, dependent: :destroy
  has_many :travel_patterns, foreign_key: :origin_zone_id, dependent: :restrict_with_error
  has_many :travel_patterns, foreign_key: :destination_zone_id, dependent: :restrict_with_error

  make_attribute_mappable :geom

  scope :ordered, -> {joins(:agency).order("agencies.name, od_zones.name")}
  scope :for_superuser, -> {all}
  scope :for_oversight_user, -> (user) {where(agency: user.current_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.current_agency.id]))}
  scope :for_current_transport_user, -> (user) {where(agency: user.current_agency)}
  scope :for_transport_user, -> (user) {where(agency: user.staff_agency)}

  validates_presence_of :agency
  validate :name_is_present?
  validates :name, uniqueness: {scope: :agency_id}

  accepts_nested_attributes_for :region

  def name_is_present?
    errors.add(:name, :blank) if self[:name].blank?
    errors.add(:name, :taken) if OdZone.where.not(id: id).exists?(name: self[:name], agency_id: agency_id)
  end

  # Build associated geographies
  def build_geographies
    build_region unless region
  end

  def self.for_user(user)
    if user.superuser?
      for_superuser
    elsif user.currently_oversight?
      for_oversight_user(user)
    elsif user.currently_transportation?
      for_current_transport_user(user)
    elsif user.transportation_user?
      for_transport_user(user)
    else
      nil
    end
  end

end