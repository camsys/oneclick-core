
# Helper class for uploading a zipped shapefile and reading it.
class ShapefileUploader
  require 'zip'

  attr_reader :errors

  # Initialize with a path to a zipfile containing shapefiles
  def initialize(file, opts={})
    @file = file
    @path = @file.tempfile.path
    @filetype = @file.content_type
    @model = opts[:geo_type].to_s.classify.constantize
    @column_mappings = opts[:column_mappings] || {name: 'NAME', state: 'STATEFP'}
    @errors = []
  end

  # Call load to process the uploaded filepath into geometric database records
  def load
    @errors.clear
    puts "Unzipping file..."
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
    puts "Unpacking shapefiles..."
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

  def load_shapefile(shp_name)
    puts "Reading Shapes into #{@model.to_s} Table..."
    RGeo::Shapefile::Reader.open(shp_name, { :assume_inner_follows_outer => true }) do |shapefile|
      fail_count = 0
      shapefile.each do |shape|
        attrs = {}
        attrs[:name] = shape.attributes[@column_mappings[:name]] if @column_mappings[:name]
        attrs[:state] = StateCodeDictionary.code(shape.attributes[@column_mappings[:stat.e]]) if @column_mappings[:state]
        geom = shape.geometry
        print "Loading #{attrs.values.join(",")}..."
        record = ActiveRecord::Base.logger.silence do
          @model.find_or_create_by(attrs).update_attributes(geom: geom)
        end
        if record
          puts " SUCCESS!"
        else
          puts " FAILED."
          fail_count += 1
        end
      end
      @errors << "#{fail_count} records failed to load." if fail_count > 0
    end
  end

end
