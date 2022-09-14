# Helper class for uploading a KML file and reading it.
class KMLUploader
  require 'geospatial/kml/reader'

  attr_reader :errors, :custom_geo, :warnings

  # Initialize with a path to a KML file
  def initialize(file, opts={})
    @file = file
    @path = opts[:path] || @file.tempfile.path
    # NOTE: the name field is specific to Travel Patterns
    @name = opts[:name]
    @agency = opts[:agency].present? ? Agency.find(opts[:agency]) : nil
    @filetype = opts[:content_type] || @file.content_type
    @model = opts[:geo_type].to_s.classify.constantize
    @column_mappings = opts[:column_mappings] || {name: 'NAME', state: 'STATEFP'}
    @errors = []
    @custom_geo = nil
    @warnings = []
  end

  # Call load to process the uploaded filepath into geometric database records
  def load
    @errors.clear
    Rails.logger.info "Opening file..."
    if @filetype == "application/vnd.google-earth.kml+xml" || @filetype == "application/octet-stream"
      load_kmlfile(@path)
    else
      @errors << "Please upload a .kml file."
    end
    return self
  end

  def successful?
    @errors.empty?
  end

  private

  def load_kmlfile(file_name)
    Rails.logger.info "Reading Shapes into #{@model.to_s} Table..."
    begin
      reader = Geospatial::KML::Reader.load_file(@path)
      reader.polygons do |polygon|
        fail_count = 0
        if @model.name == CustomGeography.name && Config.dashboard_mode == 'travel_patterns'
          attrs = {}
          if reader.polygons.count > 1
            @warnings << 'Found multiple features while creating a custom geography. Uploader only accepts one feature'
          else
            first_shape = polygon
            Rails.logger.info "Loading #{@name}..."
            polygon_points = []
            polygon.points.each do |point|
              point_str = [point[0], point[1]].join(" ")
              polygon_points.push(point_str.to_s)
            end
            polygon_wkt = 'POLYGON((' + polygon_points.join(", ").to_s + '))'
            factory = RGeo::ActiveRecord::SpatialFactoryStore.instance.default
            polygon_geom = factory.parse_wkt(polygon_wkt)
            output_geom = factory.multi_polygon([]).union(polygon_geom)
            geom = RGeo::Feature.cast(output_geom, RGeo::Feature::MultiPolygon)
            #Rails.logger.info "Parsed #{geom.to_s}"

            record = ActiveRecord::Base.logger.silence do
              @custom_geo = @model.create({ name: @name, agency: @agency })
              @custom_geo.update_attributes(geom:geom)
              # generally, the only error we're going to get are either the geometry is invalid
              # or the name was taken already
              if @custom_geo.errors.present?
                @errors << "#{@custom_geo.errors.full_messages.to_sentence} for #{@custom_geo.name}."
              else
                @custom_geo
              end
            end
          end
          if record
            Rails.logger.info " SUCCESS!"
          else
            Rails.logger.info " FAILED."
            fail_count += 1
          end
        @errors << "#{fail_count} record(s) failed to load." if fail_count > 0
        end
      end
    rescue StandardError => ex
      puts ex.message
      @errors << "An error occurred while unpacking the uploaded KML file. Please double check your KML file and try again"
    end
  end

end
