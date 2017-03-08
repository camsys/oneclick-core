class Admin::GeographiesController < Admin::AdminController

  def index
    @counties = County.all.order(:state)
  end

  def upload_counties
    puts "UPLOADING COUNTIES", params[:geographies][:file].tempfile.path

    uploader = ShapefileUploader.new(params[:geographies][:file], geo_type: :county)
    puts uploader.load.errors.ai
    # Zip::File.open(params[:geographies][:file].tempfile) do |zip_file|
    #   puts "FILE OPEN", zip_file.filepath
    #   zip_file.each do |file|
    #     puts "EXTRACTING #{file.name}"
    #   end
    # end

    # file_data = params[:geographies][:file]
    # puts file_data.respond_to?(:read)
    # puts file_data.path.to_s
    # puts Rails.root.join('public', 'uploads', file_data.original_filename)

    # RGeo::Shapefile::Reader.open(file_data.path.to_s) do |file|
    #   puts "File contains #{file.num_records} records."
    #   file.each do |record|
    #     puts "Record number #{record.index}:"
    #     puts "  Geometry: #{record.geometry.as_text}"
    #     puts "  Attributes: #{record.attributes.inspect}"
    #   end
    #   file.rewind
    #   record = file.next
    #   puts "First record geometry was: #{record.geometry.as_text}"
    # end
  end

end
