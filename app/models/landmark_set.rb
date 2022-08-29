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

  validates_presence_of :name, :agency

  def geom
    @factory = RGeo::ActiveRecord::SpatialFactoryStore.instance.default
    output_geom = self.landmarks.map do |landmark|
      geom = landmark.geom
      if geom
        if geom.is_a?(RGeo::Geos::CAPIPointImpl)
          # Convert point into polygon.
          geom = geom.buffer(0.001)
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
    GeoIngredient.new('LandmarkSet', name: name)
  end

  def self.search(term)
    where('LOWER(name) LIKE :term', term: "%#{term.downcase}%")
  end
end
