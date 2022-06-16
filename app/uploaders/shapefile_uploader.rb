
# Helper class for uploading a zipped shapefile and reading it.
class ShapefileUploader
  require 'zip'

  attr_reader :errors, :custom_geo, :warnings

  # Initialize with a path to a zipfile containing shapefiles
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
    Rails.logger.info "Unzipping file..."
    if @filetype == "application/zip"
      Zip::File.open(@path) do |zip_file|
        extract_shapefiles(zip_file) {|file| load_shapefile(file)}
      end
    else
      @errors << "Please upload a .zip file."
    end
    return self
  end

  def successful?
    @errors.empty?
  end

  private

  def extract_shapefiles(zip_file, &block)
    Rails.logger.info "Unpacking shapefiles..."
    zip_shp = zip_file.glob('**/*.shp').first
    if zip_shp
      zip_shp_paths = zip_shp.name.split('/')
      file_name = zip_shp_paths[zip_shp_paths.length - 1].sub '.shp', ''
      shp_name = nil
      Dir.mktmpdir do |dir|
        shp_name = "#{dir}/" + file_name + '.shp'
        zip_file.each do |entry|
          entry_names = entry.name.split('/')
          entry_name = entry_names[entry_names.length - 1]
          if entry_name.include?(file_name)
            entry.extract("#{dir}/" + entry_name)
          end
        end
        yield(shp_name)
      end
    else
      @errors << "Could not find .shp file in zipfile."
    end
  end

  # NOTE: Several things:
  # - shapefile loader doesn't handle bulk errors well
  #   so if all of the shapes in a shapefile don't conform to the expected attributes,
  #   the error message just says "N number of records failed to load" rather than something like:
  #   "at least one shape is missing xyz attribute" and did not create
  # - shapefiles do not include the coordinate reference system(CRS) in the metadata according to it's spec
  #   so there's no way to determine what CRS the shape is using until you check the postGIS geometry in pgAdmin or in
  #   GIS software
  def load_shapefile(shp_name)
    Rails.logger.info "Reading Shapes into #{@model.to_s} Table..."
    # Execute read Shapefile
    begin
      RGeo::Shapefile::Reader.open(shp_name,
          assume_inner_follows_outer: true,
          factory: RGeo::ActiveRecord::SpatialFactoryStore.instance.default) do |shapefile|

        fail_count = 0
        if @model.name == CustomGeography.name && Config.dashboard_mode == 'travel_patterns'
          attrs = {}
          if shapefile.num_records > 1
            @errors << 'Found multiple features while creating a custom geography. Uploader only accepts one feature'
          else
            first_shape = shapefile.get(0)
            attrs[:name] = first_shape.attributes[@column_mappings[:name]] if @column_mappings[:name]
            attrs[:state] = StateCodeDictionary.code(42) if @column_mappings[:state]
            #attrs[:state] = StateCodeDictionary.code(first_shape.attributes[@column_mappings[:state]]) if @column_mappings[:state]
            geom = first_shape.geometry
            Rails.logger.info "Loading #{attrs.values.join(",")}..."
            record = ActiveRecord::Base.logger.silence do
              @custom_geo = @model.create({ name: @name, agency: @agency })
              @custom_geo.update_attributes(geom:geom)
              # generally, the only error we're going to get are either the shapefile is invalid
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
        else
          shapefile.each do |shape|
            attrs = {}
            attrs[:name] = shape.attributes[@column_mappings[:name]] if @column_mappings[:name]
            attrs[:state] = StateCodeDictionary.code(42) if @column_mappings[:state]
            #attrs[:state] = StateCodeDictionary.code(shape.attributes[@column_mappings[:state]]) if @column_mappings[:state]
            geom = shape.geometry
            Rails.logger.info "Loading #{attrs.values.join(",")}..."

            # NOTE: the below probably needs an update since it's pretty old
            # if the record fails to create, then we can just check for record errors and push those in
            # instead of doing a weird thing with active record logger
            record = ActiveRecord::Base.logger.silence do
              # The below is overly verbose for debugging purposes
              geo = @model.find_or_create_by!(attrs)
              geo.update_attributes!(geom:geom)
              geo
            end
            if record
              Rails.logger.info " SUCCESS!"
            else
              Rails.logger.info " FAILED."
              fail_count += 1
            end
          end
        end
        @errors << "#{fail_count} record(s) failed to load." if fail_count > 0
      end
    rescue StandardError
      @errors << "An error occurred while unpacking the uploaded Shapefile. Please double check your shapefile and try again"
    end
  end

end
