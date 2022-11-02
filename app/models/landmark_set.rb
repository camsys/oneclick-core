class LandmarkSet < ApplicationRecord
  include GeoKitchen
  include LeafletAmbassador

  attr_reader :geom
  make_attribute_mappable :geom
  acts_as_geo_ingredient attributes: [:name, :buffer]

  belongs_to :agency
  has_many :landmark_set_landmarks, dependent: :destroy
  has_many :landmarks, through: :landmark_set_landmarks

  accepts_nested_attributes_for :landmark_set_landmarks, allow_destroy: true, reject_if: :all_blank

  scope :for_superuser, -> {all}
  scope :for_oversight_user, -> (user) {where(agency: user.current_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.current_agency.id]))}
  scope :for_current_transport_user, -> (user) {where(agency: user.current_agency)}
  scope :for_transport_user, -> (user) {where(agency: user.staff_agency)}

  validates_presence_of :name, :agency

  def geom
    @factory = RGeo::ActiveRecord::SpatialFactoryStore.instance.default
    @factory_simple_mercator = RGeo::Geographic.simple_mercator_factory(buffer_resolution: 8)
    output_geom = self.landmarks.map do |landmark|
      geom = landmark.geom
      if geom
        if geom.is_a?(RGeo::Geos::CAPIPointImpl)
          # Re-project point into geographic coordinate system so we can use distance units instead of degrees.
          point = RGeo::Feature.cast(geom, factory: @factory_simple_mercator, project: true)
          # Convert point into polygon.
          poly = point.buffer(GeoRecipe::DEFAULT_BUFFER_IN_FT)
          # Project point back to original system.
          geom = RGeo::Feature.cast(poly, factory: @factory, project: true)
        end
        geom
      else
        @errors << "#{landmark.to_s} could not be converted to a geometry."
        nil
      end
    end.compact.reduce(@factory.multi_polygon([])) {|combined_area, geom| combined_area.union(geom)}
    RGeo::Feature.cast(output_geom, RGeo::Feature::MultiPolygon)
  end

  def to_s
    "#{name}"
  end

  # Returns a GeoIngredient referring to this landmark set
  def to_geo
    GeoIngredient.new('LandmarkSet', name: name, buffer: GeoRecipe::DEFAULT_BUFFER_IN_FT)
  end

  def self.search(term)
    where('LOWER(name) LIKE :term', term: "%#{term.downcase}%")
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
